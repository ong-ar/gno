package v1

import (
	"std"
	"strconv"

	"gno.land/p/demo/avl"
	"gno.land/p/demo/ufmt"
)

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
}

func NewNFT(name string, symbol string, version string) *NFT {
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
	}
}

func (s *NFT) Name() string       { return s.name }
func (s *NFT) Symbol() string     { return s.symbol }
func (s *NFT) TokenCount() uint64 { return uint64(s.owners.Size()) }

// BalanceOf returns balance of input address
func (s *NFT) BalanceOf(addr std.Address) (uint64, error) {
	if err := isValidAddress(addr); err != nil {
		return 0, err
	}

	balance, found := s.getBalance(addr)
	if !found {
		return 0, nil
	}

	return balance.(uint64), nil
}

// OwnerOf returns owner of input token id
func (s *NFT) OwnerOf(tid TokenID) (std.Address, error) {
	owner, found := s.getOwner(tid)
	if !found {
		return "", ErrInvalidTokenId
	}

	return owner.(std.Address), nil
}

// TokenURI returns the URI of input token id
func (s *NFT) GetTokenURI(tid TokenID) (string, error) {
	uri, found := s.getTokenURI(tid)
	if !found {
		return "", ErrInvalidTokenId
	}

	return uri.(string), nil
}

func (s *NFT) SetTokenURI(tid TokenID, tURI TokenURI) (bool, error) {
	// check for invalid TokenID
	if !s.exists(tid) {
		return false, ErrInvalidTokenId
	}

	// check for the right owner
	owner, err := s.OwnerOf(tid)
	if err != nil {
		return false, err
	}
	caller := std.PreviousRealm().Address()
	if caller != owner {
		return false, ErrCallerIsNotOwner
	}
	s.tokenURIs.Set(string(tid), string(tURI))
	return true, nil
}

// IsApprovedForAll returns true if operator is approved for all by the owner.
// Otherwise, returns false
func (s *NFT) IsApprovedForAll(owner, operator std.Address) bool {
	key := owner.String() + ":" + operator.String()
	_, found := s.getOperatorApproval(key)
	if !found {
		return false
	}

	return true
}

// Approve approves the input address for particular token
func (s *NFT) Approve(to std.Address, tid TokenID) error {
	if err := isValidAddress(to); err != nil {
		return err
	}

	owner, err := s.OwnerOf(tid)
	if err != nil {
		return err
	}
	if owner == to {
		return ErrApprovalToCurrentOwner
	}

	caller := std.PreviousRealm().Address()
	if caller != owner && !s.IsApprovedForAll(owner, caller) {
		return ErrCallerIsNotOwnerOrApproved
	}

	s.tokenApprovals.Set(string(tid), to.String())
	std.Emit(
		ApprovalEvent,
		"owner", string(owner),
		"to", string(to),
		"tokenId", string(tid),
	)

	return nil
}

// GetApproved return the approved address for token
func (s *NFT) GetApproved(tid TokenID) (std.Address, error) {
	addr, found := s.getTokenApproval(tid)
	if !found {
		return zeroAddress, ErrTokenIdNotHasApproved
	}

	return std.Address(addr.(string)), nil
}

// SetApprovalForAll can approve the operator to operate on all tokens
func (s *NFT) SetApprovalForAll(operator std.Address, approved bool) error {
	if err := isValidAddress(operator); err != nil {
		return ErrInvalidAddress
	}

	caller := std.PreviousRealm().Address()
	return s.setApprovalForAll(caller, operator, approved)
}

// Safely transfers `tokenId` token from `from` to `to`, checking that
// contract recipients are aware of the GRC721 protocol to prevent
// tokens from being forever locked.
func (s *NFT) SafeTransferFrom(from, to std.Address, tid TokenID) error {
	caller := std.PreviousRealm().Address()
	if !s.isApprovedOrOwner(caller, tid) {
		return ErrCallerIsNotOwnerOrApproved
	}

	err := s.transfer(from, to, tid)
	if err != nil {
		return err
	}

	if !s.checkOnGRC721Received(from, to, tid) {
		return ErrTransferToNonGRC721Receiver
	}

	return nil
}

// Transfers `tokenId` token from `from` to `to`.
func (s *NFT) TransferFrom(from, to std.Address, tid TokenID) error {
	caller := std.PreviousRealm().Address()
	if !s.isApprovedOrOwner(caller, tid) {
		return ErrCallerIsNotOwnerOrApproved
	}

	err := s.transfer(from, to, tid)
	if err != nil {
		return err
	}

	return nil
}

// Mints `tokenId` and transfers it to `to`.
func (s *NFT) Mint(to std.Address, tid TokenID) error {
	return s.mint(to, tid)
}

// Mints `tokenId` and transfers it to `to`. Also checks that
// contract recipients are using GRC721 protocol
func (s *NFT) SafeMint(to std.Address, tid TokenID) error {
	err := s.mint(to, tid)
	if err != nil {
		return err
	}

	if !s.checkOnGRC721Received(zeroAddress, to, tid) {
		return ErrTransferToNonGRC721Receiver
	}

	return nil
}

func (s *NFT) Burn(tid TokenID) error {
	owner, err := s.OwnerOf(tid)
	if err != nil {
		return err
	}

	s.beforeTokenTransfer(owner, zeroAddress, tid, 1)

	s.tokenApprovals.Remove(string(tid))
	balance, err := s.BalanceOf(owner)
	if err != nil {
		return err
	}
	balance -= 1
	s.balances.Set(owner.String(), balance)
	s.owners.Remove(string(tid))
	s.burnedOwners.Set(string(tid), owner)

	std.Emit(
		BurnEvent,
		"from", string(owner),
		"tokenId", string(tid),
	)

	s.afterTokenTransfer(owner, zeroAddress, tid, 1)

	return nil
}

/* Helper methods */

// Helper for SetApprovalForAll()
func (s *NFT) setApprovalForAll(owner, operator std.Address, approved bool) error {
	if owner == operator {
		return ErrApprovalToCurrentOwner
	}

	key := owner.String() + ":" + operator.String()
	s.operatorApprovals.Set(key, approved)

	std.Emit(
		ApprovalForAllEvent,
		"owner", string(owner),
		"to", string(operator),
		"approved", strconv.FormatBool(approved),
	)

	return nil
}

// Helper for TransferFrom() and SafeTransferFrom()
func (s *NFT) transfer(from, to std.Address, tid TokenID) error {
	if err := isValidAddress(from); err != nil {
		return ErrInvalidAddress
	}
	if err := isValidAddress(to); err != nil {
		return ErrInvalidAddress
	}

	if from == to {
		return ErrCannotTransferToSelf
	}

	owner, err := s.OwnerOf(tid)
	if err != nil {
		return err
	}
	if owner != from {
		return ErrTransferFromIncorrectOwner
	}

	s.beforeTokenTransfer(from, to, tid, 1)

	// Check that tokenId was not transferred by `beforeTokenTransfer`
	owner, err = s.OwnerOf(tid)
	if err != nil {
		return err
	}
	if owner != from {
		return ErrTransferFromIncorrectOwner
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

	std.Emit(
		TransferEvent,
		"from", string(from),
		"to", string(to),
		"tokenId", string(tid),
	)

	s.afterTokenTransfer(from, to, tid, 1)

	return nil
}

// Helper for Mint() and SafeMint()
func (s *NFT) mint(to std.Address, tid TokenID) error {
	if err := isValidAddress(to); err != nil {
		return err
	}

	if s.exists(tid) {
		return ErrTokenIdAlreadyExists
	}

	s.beforeTokenTransfer(zeroAddress, to, tid, 1)

	// Check that tokenId was not minted by `beforeTokenTransfer`
	if s.exists(tid) {
		return ErrTokenIdAlreadyExists
	}

	toBalance, err := s.BalanceOf(to)
	if err != nil {
		return err
	}
	toBalance += 1
	s.balances.Set(to.String(), toBalance)
	s.owners.Set(string(tid), to)

	std.Emit(
		MintEvent,
		"to", string(to),
		"tokenId", string(tid),
	)

	s.afterTokenTransfer(zeroAddress, to, tid, 1)

	return nil
}

func (s *NFT) isApprovedOrOwner(addr std.Address, tid TokenID) bool {
	owner, found := s.getOwner(tid)
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
func (s *NFT) exists(tid TokenID) bool {
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

func (s *NFT) beforeTokenTransfer(from, to std.Address, firstTokenId TokenID, batchSize uint64) {
	// TODO: Implementation
}

func (s *NFT) afterTokenTransfer(from, to std.Address, firstTokenId TokenID, batchSize uint64) {
	// TODO: Implementation
}

func (s *NFT) checkOnGRC721Received(from, to std.Address, tid TokenID) bool {
	// TODO: Implementation
	return true
}

func (s *NFT) RenderHome() (str string) {
	str += ufmt.Sprintf("# %s ($%s)\n\n", s.name, s.symbol)
	str += ufmt.Sprintf("* **Total supply**: %d\n", s.TokenCount())
	str += ufmt.Sprintf("* **Known accounts**: %d\n", s.balances.Size())

	return
}

// getter
func (s *NFT) getBalance(addr std.Address) (any, bool) {
	balance, found := s.balances.Get(addr.String())

	return balance, found
}

func (s *NFT) getOwner(tid TokenID) (any, bool) {
	owner, found := s.owners.Get(string(tid))

	return owner, found
}

func (s *NFT) getBurnedOwner(tid TokenID) (any, bool) {
	burnedOwner, found := s.burnedOwners.Get(string(tid))

	return burnedOwner, found
}

func (s *NFT) getTokenURI(tid TokenID) (any, bool) {
	uri, found := s.tokenURIs.Get(string(tid))

	return uri, found
}

func (s *NFT) getOperatorApproval(key string) (any, bool) {
	operatorApproval, found := s.operatorApprovals.Get(key)

	return operatorApproval, found
}

func (s *NFT) getTokenApproval(tid TokenID) (any, bool) {
	tokenApproval, found := s.tokenApprovals.Get(string(tid))

	return tokenApproval, found
}

