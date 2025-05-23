package state

import (
	"errors"
	"fmt"

	"github.com/gnolang/gno/tm2/pkg/amino"
	abci "github.com/gnolang/gno/tm2/pkg/bft/abci/types"
	"github.com/gnolang/gno/tm2/pkg/bft/types"
	dbm "github.com/gnolang/gno/tm2/pkg/db"
	osm "github.com/gnolang/gno/tm2/pkg/os"
)

const (
	// persist validators every valSetCheckpointInterval blocks to avoid
	// LoadValidators taking too much time.
	// https://github.com/tendermint/classic/pull/3438
	// 100000 results in ~ 100ms to get 100 validators (see BenchmarkLoadValidators)
	valSetCheckpointInterval = 100000
)

var errTxResultIndexCorrupted = errors.New("tx result index corrupted")

// ------------------------------------------------------------------------

func calcValidatorsKey(height int64) []byte {
	return fmt.Appendf(nil, "validatorsKey:%x", height)
}

func calcConsensusParamsKey(height int64) []byte {
	return fmt.Appendf(nil, "consensusParamsKey:%x", height)
}

func CalcABCIResponsesKey(height int64) []byte {
	return fmt.Appendf(nil, "abciResponsesKey:%x", height)
}

// CalcTxResultKey calculates the storage key for the transaction result
func CalcTxResultKey(hash []byte) []byte {
	return fmt.Appendf(nil, "txResultKey:%x", hash)
}

// LoadStateFromDBOrGenesisFile loads the most recent state from the database,
// or creates a new one from the given genesisFilePath and persists the result
// to the database.
func LoadStateFromDBOrGenesisFile(stateDB dbm.DB, genesisFilePath string) (State, error) {
	state := LoadState(stateDB)
	if state.IsEmpty() {
		var err error
		state, err = MakeGenesisStateFromFile(genesisFilePath)
		if err != nil {
			return state, err
		}
		SaveState(stateDB, state)
	}

	return state, nil
}

// LoadStateFromDBOrGenesisDoc loads the most recent state from the database,
// or creates a new one from the given genesisDoc and persists the result
// to the database.
func LoadStateFromDBOrGenesisDoc(stateDB dbm.DB, genesisDoc *types.GenesisDoc) (State, error) {
	state := LoadState(stateDB)
	if state.IsEmpty() {
		var err error
		state, err = MakeGenesisState(genesisDoc)
		if err != nil {
			return state, err
		}
		SaveState(stateDB, state)
	}

	return state, nil
}

// LoadState loads the State from the database.
func LoadState(db dbm.DB) State {
	return loadState(db, stateKey)
}

func loadState(db dbm.DB, key []byte) (state State) {
	buf := db.Get(key)
	if len(buf) == 0 {
		return state
	}

	err := amino.Unmarshal(buf, &state)
	if err != nil {
		// DATA HAS BEEN CORRUPTED OR THE SPEC HAS CHANGED
		osm.Exit(fmt.Sprintf(`LoadState: Data has been corrupted or its spec has changed:
                %v\n`, err))
	}
	// TODO: ensure that buf is completely read.

	return state
}

// SaveState persists the State, the ValidatorsInfo, and the ConsensusParamsInfo to the database.
// This flushes the writes (e.g. calls SetSync).
func SaveState(db dbm.DB, state State) {
	saveState(db, state, stateKey)
}

func saveState(db dbm.DB, state State, key []byte) {
	nextHeight := state.LastBlockHeight + 1
	// If first block, save validators for block 1.
	if nextHeight == 1 {
		// This extra logic due to Tendermint validator set changes being delayed 1 block.
		// It may get overwritten due to InitChain validator updates.
		lastHeightVoteChanged := int64(1)
		saveValidatorsInfo(db, nextHeight, lastHeightVoteChanged, state.Validators)
	}
	// Save next validators.
	saveValidatorsInfo(db, nextHeight+1, state.LastHeightValidatorsChanged, state.NextValidators)
	// Save next consensus params.
	saveConsensusParamsInfo(db, nextHeight, state.LastHeightConsensusParamsChanged, state.ConsensusParams)
	db.SetSync(key, state.Bytes())
}

// ------------------------------------------------------------------------

// ABCIResponses retains the responses
// of the various ABCI calls during block processing.
// It is persisted to disk for each height before calling Commit.
type ABCIResponses struct {
	DeliverTxs []abci.ResponseDeliverTx `json:"deliver_tx"`
	EndBlock   abci.ResponseEndBlock    `json:"end_block"`
	BeginBlock abci.ResponseBeginBlock  `json:"begin_block"`
}

// NewABCIResponses returns a new ABCIResponses
func NewABCIResponses(block *types.Block) *ABCIResponses {
	return NewABCIResponsesFromNum(block.NumTxs)
}

// NewABCIResponsesFromNum returns a new ABCIResponses with a set number of txs
func NewABCIResponsesFromNum(numTxs int64) *ABCIResponses {
	resDeliverTxs := make([]abci.ResponseDeliverTx, numTxs)
	if numTxs == 0 {
		// This makes Amino encoding/decoding consistent.
		resDeliverTxs = nil
	}
	return &ABCIResponses{
		DeliverTxs: resDeliverTxs,
	}
}

// Bytes serializes the ABCIResponse using go-amino.
func (arz *ABCIResponses) Bytes() []byte {
	return amino.MustMarshal(arz)
}

func (arz *ABCIResponses) ResultsHash() []byte {
	results := types.NewResults(arz.DeliverTxs)
	return results.Hash()
}

// LoadABCIResponses loads the ABCIResponses for the given height from the database.
// This is useful for recovering from crashes where we called app.Commit and before we called
// s.Save(). It can also be used to produce Merkle proofs of the result of txs.
func LoadABCIResponses(db dbm.DB, height int64) (*ABCIResponses, error) {
	buf := db.Get(CalcABCIResponsesKey(height))
	if buf == nil {
		return nil, NoABCIResponsesForHeightError{height}
	}

	abciResponses := new(ABCIResponses)
	err := amino.Unmarshal(buf, abciResponses)
	if err != nil {
		// DATA HAS BEEN CORRUPTED OR THE SPEC HAS CHANGED
		osm.Exit(fmt.Sprintf(`LoadABCIResponses: Data has been corrupted or its spec has
                changed: %v\n`, err))
	}
	// TODO: ensure that buf is completely read.

	return abciResponses, nil
}

// SaveABCIResponses persists the ABCIResponses to the database.
// This is useful in case we crash after app.Commit and before s.Save().
// Responses are indexed by height so they can also be loaded later to produce Merkle proofs.
// NOTE: this should only be used internally by the bft package and subpackages.
func SaveABCIResponses(db dbm.DB, height int64, abciResponses *ABCIResponses) {
	db.Set(CalcABCIResponsesKey(height), abciResponses.Bytes())
}

// TxResultIndex keeps the result index information for a transaction
type TxResultIndex struct {
	BlockNum int64  // the block number the tx was contained in
	TxIndex  uint32 // the index of the transaction within the block
}

func (t *TxResultIndex) Bytes() []byte {
	return amino.MustMarshal(t)
}

// LoadTxResultIndex loads the tx result associated with the given
// tx hash from the database, if any
func LoadTxResultIndex(db dbm.DB, txHash []byte) (*TxResultIndex, error) {
	buf := db.Get(CalcTxResultKey(txHash))
	if buf == nil {
		return nil, NoTxResultForHashError{txHash}
	}

	txResultIndex := new(TxResultIndex)
	if err := amino.Unmarshal(buf, txResultIndex); err != nil {
		return nil, fmt.Errorf("%w, %w", errTxResultIndexCorrupted, err)
	}

	return txResultIndex, nil
}

// saveTxResultIndex persists the transaction result index to the database
func saveTxResultIndex(db dbm.DB, txHash []byte, resultIndex TxResultIndex) {
	db.Set(CalcTxResultKey(txHash), resultIndex.Bytes())
}

// -----------------------------------------------------------------------------

// ValidatorsInfo represents the latest validator set, or the last height it changed
type ValidatorsInfo struct {
	ValidatorSet      *types.ValidatorSet
	LastHeightChanged int64
}

// Bytes serializes the ValidatorsInfo using go-amino.
func (valInfo *ValidatorsInfo) Bytes() []byte {
	return amino.MustMarshal(valInfo)
}

// LoadValidators loads the ValidatorSet for a given height.
// Returns NoValSetForHeightError if the validator set can't be found for this height.
func LoadValidators(db dbm.DB, height int64) (*types.ValidatorSet, error) {
	valInfo := loadValidatorsInfo(db, height)
	if valInfo == nil {
		return nil, NoValSetForHeightError{height}
	}
	if valInfo.ValidatorSet == nil {
		lastStoredHeight := lastStoredHeightFor(height, valInfo.LastHeightChanged)
		valInfo2 := loadValidatorsInfo(db, lastStoredHeight)
		if valInfo2 == nil || valInfo2.ValidatorSet == nil {
			// TODO (melekes): remove the below if condition in the 0.33 major
			// release and just panic. Old chains might panic otherwise if they
			// haven't saved validators at intermediate (%valSetCheckpointInterval)
			// height yet.
			// https://github.com/tendermint/classic/issues/3543
			valInfo2 = loadValidatorsInfo(db, valInfo.LastHeightChanged)
			lastStoredHeight = valInfo.LastHeightChanged
			if valInfo2 == nil || valInfo2.ValidatorSet == nil {
				panic(
					fmt.Sprintf("Couldn't find validators at height %d (height %d was originally requested)",
						lastStoredHeight,
						height,
					),
				)
			}
		}
		valInfo2.ValidatorSet.IncrementProposerPriority(int(height - lastStoredHeight)) // mutate
		valInfo = valInfo2
	}

	return valInfo.ValidatorSet, nil
}

func lastStoredHeightFor(height, lastHeightChanged int64) int64 {
	checkpointHeight := height - height%valSetCheckpointInterval
	return max(checkpointHeight, lastHeightChanged)
}

// CONTRACT: Returned ValidatorsInfo can be mutated.
func loadValidatorsInfo(db dbm.DB, height int64) *ValidatorsInfo {
	buf := db.Get(calcValidatorsKey(height))
	if len(buf) == 0 {
		return nil
	}

	v := new(ValidatorsInfo)
	err := amino.Unmarshal(buf, v)
	if err != nil {
		// DATA HAS BEEN CORRUPTED OR THE SPEC HAS CHANGED
		osm.Exit(fmt.Sprintf(`LoadValidators: Data has been corrupted or its spec has changed:
                %v\n`, err))
	}
	// TODO: ensure that buf is completely read.

	return v
}

// saveValidatorsInfo persists the validator set.
//
// `height` is the effective height for which the validator is responsible for
// signing. It should be called from s.Save(), right before the state itself is
// persisted.
func saveValidatorsInfo(db dbm.DB, height, lastHeightChanged int64, valSet *types.ValidatorSet) {
	if lastHeightChanged > height {
		panic("LastHeightChanged cannot be greater than ValidatorsInfo height")
	}
	valInfo := &ValidatorsInfo{
		LastHeightChanged: lastHeightChanged,
	}
	// Only persist validator set if it was updated or checkpoint height (see
	// valSetCheckpointInterval) is reached.
	if height == lastHeightChanged || height%valSetCheckpointInterval == 0 {
		valInfo.ValidatorSet = valSet
	}
	db.Set(calcValidatorsKey(height), valInfo.Bytes())
}

// -----------------------------------------------------------------------------

// ConsensusParamsInfo represents the latest consensus params, or the last height it changed
type ConsensusParamsInfo struct {
	ConsensusParams   abci.ConsensusParams
	LastHeightChanged int64
}

// Bytes serializes the ConsensusParamsInfo using go-amino.
func (params ConsensusParamsInfo) Bytes() []byte {
	return amino.MustMarshal(params)
}

// LoadConsensusParams loads the ConsensusParams for a given height.
func LoadConsensusParams(db dbm.DB, height int64) (abci.ConsensusParams, error) {
	empty := abci.ConsensusParams{}

	paramsInfo := loadConsensusParamsInfo(db, height)
	if paramsInfo == nil {
		return empty, NoConsensusParamsForHeightError{height}
	}

	if amino.DeepEqual(empty, paramsInfo.ConsensusParams) {
		paramsInfo2 := loadConsensusParamsInfo(db, paramsInfo.LastHeightChanged)
		if paramsInfo2 == nil {
			panic(
				fmt.Sprintf(
					"Couldn't find consensus params at height %d as last changed from height %d",
					paramsInfo.LastHeightChanged,
					height,
				),
			)
		}
		paramsInfo = paramsInfo2
	}

	return paramsInfo.ConsensusParams, nil
}

func loadConsensusParamsInfo(db dbm.DB, height int64) *ConsensusParamsInfo {
	buf := db.Get(calcConsensusParamsKey(height))
	if len(buf) == 0 {
		return nil
	}

	paramsInfo := new(ConsensusParamsInfo)
	err := amino.Unmarshal(buf, paramsInfo)
	if err != nil {
		// DATA HAS BEEN CORRUPTED OR THE SPEC HAS CHANGED
		osm.Exit(fmt.Sprintf(`LoadConsensusParams: Data has been corrupted or its spec has changed:
                %v\n`, err))
	}
	// TODO: ensure that buf is completely read.

	return paramsInfo
}

// saveConsensusParamsInfo persists the consensus params for the next block to disk.
// It should be called from s.Save(), right before the state itself is persisted.
// If the consensus params did not change after processing the latest block,
// only the last height for which they changed is persisted.
func saveConsensusParamsInfo(db dbm.DB, nextHeight, changeHeight int64, params abci.ConsensusParams) {
	paramsInfo := &ConsensusParamsInfo{
		LastHeightChanged: changeHeight,
	}
	if changeHeight == nextHeight {
		paramsInfo.ConsensusParams = params
	}
	db.Set(calcConsensusParamsKey(nextHeight), paramsInfo.Bytes())
}
