package v1

import (
	"std"
	"strconv"

	"gno.land/p/demo/avl"
	"gno.land/p/demo/ufmt"
	"gno.land/p/demo/grc/grc721"
)

const zeroAddress = std.Address("")

type NFT struct {
	name              string
	symbol            string
	version           string
	owners            avl.Tree // tokenId -> OwnerAddress
	burnedOwners	  avl.Tree // tokenId -> OwnerAddress
	balances          avl.Tree // OwnerAddress -> TokenCount
	tokenApprovals    avl.Tree // TokenId -> ApprovedAddress
	tokenURIs         avl.Tree // TokenId -> URIs
	operatorApprovals avl.Tree // "OwnerAddress:OperatorAddress" -> bool
	ownedTokenIDs     avl.Tree
	totalSupply       uint64
}

func newNFT(name string, symbol string, version string) *NFT {
	return &NFT{
		name:              name,
		symbol:            symbol,
		version:           version,

		owners:            avl.Tree{},
		burnedOwners:      avl.Tree{},
		balances:          avl.Tree{},
		tokenApprovals:    avl.Tree{},
		tokenURIs:         avl.Tree{},
		operatorApprovals: avl.Tree{},
		ownedTokenIDs:     avl.Tree{},
		totalSupply:       0,
	}
}

func (s *NFT) Name() string       { return s.name }
func (s *NFT) Symbol() string     { return s.symbol }
func (s *NFT) Version() string    { return s.version }
func (s *NFT) TokenCount() uint64 { return s.ZZ_GetTotalSupply() }

// BalanceOf returns balance of input address
func (s *NFT) BalanceOf(addr std.Address) (uint64, error) {
	if err := isValidAddress(addr); err != nil {
		return 0, err
	}

	balance, found := s.ZZ_GetBalance(addr)
	if !found {
		return 0, nil
	}

	return balance.(uint64), nil
}

// OwnerOf returns owner of input token id
func (s *NFT) OwnerOf(tid grc721.TokenID) (std.Address, error) {
	owner, found := s.ZZ_GetOwner(tid)
	if !found {
		return "", grc721.ErrInvalidTokenId
	}

	return owner.(std.Address), nil
}

// TokenIDsOf returns token ids of input address
func (s *NFT) TokenIDsOf(addr std.Address) ([]string, error) {
	if err := isValidAddress(addr); err != nil {
		return []string{}, err
	}

	tokenIDs, found := s.ZZ_GetOwnedTokenIDs(addr)
	if !found {
		return []string{}, nil
	}

	return tokenIDs.([]string), nil
}

// TokenURI returns the URI of input token id
func (s *NFT) GetTokenURI(tid grc721.TokenID) (string, error) {
	uri, found := s.ZZ_GetTokenURI(tid)
	if !found {
		return "", grc721.ErrInvalidTokenId
	}

	return uri.(string), nil
}

func (s *NFT) SetTokenURI(tid grc721.TokenID, tURI grc721.TokenURI) (bool, error) {
	// check for invalid grc721.TokenID
	if !s.exists(tid) {
		return false, grc721.ErrInvalidTokenId
	}

	// check for the right owner
	owner, err := s.OwnerOf(tid)
	if err != nil {
		return false, err
	}
	caller := std.PreviousRealm().Address()
	if caller != owner {
		return false, grc721.ErrCallerIsNotOwner
	}
	s.tokenURIs.Set(string(tid), string(tURI))
	return true, nil
}

// IsApprovedForAll returns true if operator is approved for all by the owner.
// Otherwise, returns false
func (s *NFT) IsApprovedForAll(owner, operator std.Address) bool {
	key := owner.String() + ":" + operator.String()
	_, found := s.ZZ_GetOperatorApproval(key)
	if !found {
		return false
	}

	return true
}

// Approve approves the input address for particular token
func (s *NFT) Approve(to std.Address, tid grc721.TokenID) error {
	if err := isValidAddress(to); err != nil {
		return err
	}

	owner, err := s.OwnerOf(tid)
	if err != nil {
		return err
	}
	if owner == to {
		return grc721.ErrApprovalToCurrentOwner
	}

	caller := std.PreviousRealm().Address()
	if caller != owner && !s.IsApprovedForAll(owner, caller) {
		return grc721.ErrCallerIsNotOwnerOrApproved
	}

	s.tokenApprovals.Set(string(tid), to.String())
	std.Emit(
		grc721.ApprovalEvent,
		"owner", string(owner),
		"to", string(to),
		"tokenId", string(tid),
	)

	return nil
}

// GetApproved return the approved address for token
func (s *NFT) GetApproved(tid grc721.TokenID) (std.Address, error) {
	addr, found := s.ZZ_GetTokenApproval(tid)
	if !found {
		return zeroAddress, grc721.ErrTokenIdNotHasApproved
	}

	return std.Address(addr.(string)), nil
}

// SetApprovalForAll can approve the operator to operate on all tokens
func (s *NFT) SetApprovalForAll(operator std.Address, approved bool) error {
	if err := isValidAddress(operator); err != nil {
		return grc721.ErrInvalidAddress
	}

	caller := std.PreviousRealm().Address()
	return s.setApprovalForAll(caller, operator, approved)
}

// Safely transfers `tokenId` token from `from` to `to`, checking that
// contract recipients are aware of the GRC721 protocol to prevent
// tokens from being forever locked.
func (s *NFT) SafeTransferFrom(from, to std.Address, tid grc721.TokenID) error {
	caller := std.PreviousRealm().Address()
	if !s.isApprovedOrOwner(caller, tid) {
		return grc721.ErrCallerIsNotOwnerOrApproved
	}

	err := s.transfer(from, to, tid)
	if err != nil {
		return err
	}

	return nil
}

// Transfers `tokenId` token from `from` to `to`.
func (s *NFT) TransferFrom(from, to std.Address, tid grc721.TokenID) error {
	caller := std.PreviousRealm().Address()
	if !s.isApprovedOrOwner(caller, tid) {
		return grc721.ErrCallerIsNotOwnerOrApproved
	}

	err := s.transfer(from, to, tid)
	if err != nil {
		return err
	}

	return nil
}

// Mints `tokenId` and transfers it to `to`.
func (s *NFT) Mint(to std.Address, tid grc721.TokenID) error {
	return s.mint(to, tid)
}

// Mints `tokenId` and transfers it to `to`. Also checks that
// contract recipients are using GRC721 protocol
func (s *NFT) SafeMint(to std.Address, tid grc721.TokenID) error {
	err := s.mint(to, tid)
	if err != nil {
		return err
	}

	return nil
}

func (s *NFT) Burn(tid grc721.TokenID) error {
	owner, err := s.OwnerOf(tid)
	if err != nil {
		return err
	}

	s.tokenApprovals.Remove(string(tid))
	balance, err := s.BalanceOf(owner)
	if err != nil {
		return err
	}
	balance -= 1
	s.balances.Set(owner.String(), balance)
	s.owners.Remove(string(tid))
	s.burnedOwners.Set(string(tid), owner)
	s.removeTokenFromOwner(owner, tid)

	s.totalSupply -= 1

	std.Emit(
		grc721.BurnEvent,
		"from", string(owner),
		"tokenId", string(tid),
	)

	return nil
}

/* Helper methods */

// Helper for SetApprovalForAll()
func (s *NFT) setApprovalForAll(owner, operator std.Address, approved bool) error {
	if owner == operator {
		return grc721.ErrApprovalToCurrentOwner
	}

	key := owner.String() + ":" + operator.String()
	s.operatorApprovals.Set(key, approved)

	std.Emit(
		grc721.ApprovalForAllEvent,
		"owner", string(owner),
		"to", string(operator),
		"approved", strconv.FormatBool(approved),
	)

	return nil
}

// Helper for TransferFrom() and SafeTransferFrom()
func (s *NFT) transfer(from, to std.Address, tid grc721.TokenID) error {
	if err := isValidAddress(from); err != nil {
		return grc721.ErrInvalidAddress
	}
	if err := isValidAddress(to); err != nil {
		return grc721.ErrInvalidAddress
	}

	if from == to {
		return grc721.ErrCannotTransferToSelf
	}

	owner, err := s.OwnerOf(tid)
	if err != nil {
		return err
	}
	if owner != from {
		return grc721.ErrTransferFromIncorrectOwner
	}

	owner, err = s.OwnerOf(tid)
	if err != nil {
		return err
	}
	if owner != from {
		return grc721.ErrTransferFromIncorrectOwner
	}

	s.tokenApprovals.Remove(string(tid))
	fromBalance, err := s.BalanceOf(from)
	if err != nil {
		return err
	}
	toBalance, err := s.BalanceOf(to)
	if err != nil {
		return err
	}
	fromBalance -= 1
	toBalance += 1
	s.balances.Set(from.String(), fromBalance)
	s.balances.Set(to.String(), toBalance)
	s.owners.Set(string(tid), to)
	s.removeTokenFromOwner(from, tid)
	s.addTokenToOwner(to, tid)

	std.Emit(
		grc721.TransferEvent,
		"from", string(from),
		"to", string(to),
		"tokenId", string(tid),
	)

	return nil
}

// Helper for Mint() and SafeMint()
func (s *NFT) mint(to std.Address, tid grc721.TokenID) error {
	if err := isValidAddress(to); err != nil {
		return err
	}

	if s.exists(tid) {
		return grc721.ErrTokenIdAlreadyExists
	}

	if s.exists(tid) {
		return grc721.ErrTokenIdAlreadyExists
	}

	toBalance, err := s.BalanceOf(to)
	if err != nil {
		return err
	}
	toBalance += 1
	s.balances.Set(to.String(), toBalance)
	s.owners.Set(string(tid), to)
	s.addTokenToOwner(to, tid)

	s.totalSupply += 1

	std.Emit(
		grc721.MintEvent,
		"to", string(to),
		"tokenId", string(tid),
	)

	return nil
}

func (s *NFT) isApprovedOrOwner(addr std.Address, tid grc721.TokenID) bool {
	owner, found := s.ZZ_GetOwner(tid)
	if !found {
		return false
	}

	if addr == owner.(std.Address) || s.IsApprovedForAll(owner.(std.Address), addr) {
		return true
	}

	approved, err := s.GetApproved(tid)
	if err != nil {
		return false
	}

	return approved == addr
}

// Checks if token id already exists
func (s *NFT) exists(tid grc721.TokenID) bool {
	_, found := s.owners.Get(string(tid))

	if found {
		return found
	}

	_, foundBurned := s.burnedOwners.Get(string(tid))

	if foundBurned {
		return foundBurned
	}

	return false
}

func (s *NFT) addTokenToOwner(owner std.Address, tid grc721.TokenID) {
	val, found := s.ZZ_GetOwnedTokenIDs(owner)
	var tokenIDs []string
	if found {
		tokenIDs = val.([]string)
	}
	tokenIDs = append(tokenIDs, string(tid))
	s.ownedTokenIDs.Set(owner.String(), tokenIDs)
}

func (s *NFT) removeTokenFromOwner(owner std.Address, tid grc721.TokenID) {
	val, found := s.ZZ_GetOwnedTokenIDs(owner)
	if !found {
		return
	}

	var tokenIDs []string
	for _, id := range val.([]string) {
		if id != string(tid) {
			tokenIDs = append(tokenIDs, id)
		}
	}

	if len(tokenIDs) == 0 {
		s.ownedTokenIDs.Remove(owner.String())
	} else {
		s.ownedTokenIDs.Set(owner.String(), tokenIDs)
	}
}

func (s *NFT) RenderHome() (str string) {
	str += ufmt.Sprintf("# %s ($%s)\n\n", s.name, s.symbol)
	str += ufmt.Sprintf("* **Total supply**: %d\n", s.TokenCount())
	str += ufmt.Sprintf("* **Known accounts**: %d\n", s.balances.Size())

	return
}

// getter
func (s *NFT) ZZ_GetBalance(addr std.Address) (any, bool) {
	balance, found := s.balances.Get(addr.String())

	return balance, found
}

func (s *NFT) ZZ_GetOwner(tid grc721.TokenID) (any, bool) {
	owner, found := s.owners.Get(string(tid))

	return owner, found
}

func (s *NFT) ZZ_GetBurnedOwner(tid grc721.TokenID) (any, bool) {
	burnedOwner, found := s.burnedOwners.Get(string(tid))

	return burnedOwner, found
}

func (s *NFT) ZZ_GetTokenURI(tid grc721.TokenID) (any, bool) {
	uri, found := s.tokenURIs.Get(string(tid))

	return uri, found
}

func (s *NFT) ZZ_GetOperatorApproval(key string) (any, bool) {
	operatorApproval, found := s.operatorApprovals.Get(key)

	return operatorApproval, found
}

func (s *NFT) ZZ_GetTokenApproval(tid grc721.TokenID) (any, bool) {
	tokenApproval, found := s.tokenApprovals.Get(string(tid))

	return tokenApproval, found
}

func (s *NFT) ZZ_GetTotalSupply() uint64 {
	return s.totalSupply
}

func (s *NFT) ZZ_GetOwnedTokenIDs(addr std.Address) (any, bool) {
	tokenIDs, found := s.ownedTokenIDs.Get(addr.String())

	return tokenIDs, found
}
