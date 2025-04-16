package v2

import (
	"std"
	"strconv"

	"gno.land/p/demo/grc/grc721"
	"gno.land/p/demo/ufmt"
)

// external methods

func Name() string       { return *name }
func Symbol() string     { return *symbol }
func TokenCount() uint64 { return uint64((*owners).Size()) }


func BalanceOf(user std.Address) uint64 {
	balance, err := iBalanceOf(user)
	if err != nil {
		panic(err)
	}

	return balance
}

func OwnerOf(tid grc721.TokenID) std.Address {
	owner, err := iOwnerOf(tid)
	if err != nil {
		panic(err)
	}

	return owner
}


func IsApprovedForAll(owner, user std.Address) bool {
	return iIsApprovedForAll(owner, user)
}

func GetApproved(tid grc721.TokenID) std.Address {
	addr, err := iGetApproved(tid)
	if err != nil {
		panic(err)
	}

	return addr
}

// Setters
func Approve(user std.Address, tid grc721.TokenID) {
	err := iApprove(user, tid)
	if err != nil {
		panic(err)
	}
}

func SetApprovalForAll(user std.Address, approved bool) {
	err := iSetApprovalForAll(user, approved)
	if err != nil {
		panic(err)
	}
}

func TransferFrom(from, to std.Address, tid grc721.TokenID) {
	err := iTransferFrom(from, to, tid)
	if err != nil {
		panic(err)
	}
}

// Admin
func Mint(to std.Address, tid grc721.TokenID) {
	caller := std.PreviousRealm().Address()
	assertIsAdmin(caller)
	err := iMint(to, tid)
	if err != nil {
		panic(err)
	}
}

func Burn(tid grc721.TokenID) {
	caller := std.PreviousRealm().Address()
	assertIsAdmin(caller)
	err := iBurn(tid)
	if err != nil {
		panic(err)
	}
}

// Render
func Render(path string) string {
	switch {
	case path == "":
		return iRenderHome()
	default:
		return "404\n"
	}
}

// internal methods

// BalanceOf returns balance of input address
func iBalanceOf(addr std.Address) (uint64, error) {
	if err := isValidAddress(addr); err != nil {
		return 0, err
	}

	balance, found := (*balances).Get(addr.String())
	if !found {
		return 0, nil
	}

	return balance.(uint64), nil
}

// OwnerOf returns owner of input token id
func iOwnerOf(tid grc721.TokenID) (std.Address, error) {
	owner, found := (*owners).Get(string(tid))
	if !found {
		return "", grc721.ErrInvalidTokenId
	}

	return owner.(std.Address), nil
}

// TokenURI returns the URI of input token id
func iTokenURI(tid grc721.TokenID) (string, error) {
	uri, found := (*tokenURIs).Get(string(tid))
	if !found {
		return "", grc721.ErrInvalidTokenId
	}

	return uri.(string), nil
}

func iSetTokenURI(tid grc721.TokenID, tURI grc721.TokenURI) (bool, error) {
	// check for invalid grc721.TokenID
	if !exists(tid) {
		return false, grc721.ErrInvalidTokenId
	}

	// check for the right owner
	owner, err := iOwnerOf(tid)
	if err != nil {
		return false, err
	}
	caller := std.PreviousRealm().Address()
	if caller != owner {
		return false, grc721.ErrCallerIsNotOwner
	}
	(*tokenURIs).Set(string(tid), string(tURI))
	return true, nil
}

// IsApprovedForAll returns true if operator is approved for all by the owner.
// Otherwise, returns false
func iIsApprovedForAll(owner, operator std.Address) bool {
	key := owner.String() + ":" + operator.String()
	_, found := (*operatorApprovals).Get(key)
	if !found {
		return false
	}

	return true
}

// Approve approves the input address for particular token
func iApprove(to std.Address, tid grc721.TokenID) error {
	if err := isValidAddress(to); err != nil {
		return err
	}

	owner, err := iOwnerOf(tid)
	if err != nil {
		return err
	}
	if owner == to {
		return grc721.ErrApprovalToCurrentOwner
	}

	caller := std.PreviousRealm().Address()
	if caller != owner && !iIsApprovedForAll(owner, caller) {
		return grc721.ErrCallerIsNotOwnerOrApproved
	}

	(*tokenApprovals).Set(string(tid), to.String())
	std.Emit(
		grc721.ApprovalEvent,
		"owner", string(owner),
		"to", string(to),
		"tokenId", string(tid),
	)

	return nil
}

// GetApproved return the approved address for token
func iGetApproved(tid grc721.TokenID) (std.Address, error) {
	addr, found := (*tokenApprovals).Get(string(tid))
	if !found {
		return zeroAddress, grc721.ErrTokenIdNotHasApproved
	}

	return std.Address(addr.(string)), nil
}

// SetApprovalForAll can approve the operator to operate on all tokens
func iSetApprovalForAll(operator std.Address, approved bool) error {
	if err := isValidAddress(operator); err != nil {
		return grc721.ErrInvalidAddress
	}

	caller := std.PreviousRealm().Address()
	return setApprovalForAll(caller, operator, approved)
}

// Safely transfers `tokenId` token from `from` to `to`, checking that
// contract recipients are aware of the GRC721 protocol to prevent
// tokens from being forever locked.
func iSafeTransferFrom(from, to std.Address, tid grc721.TokenID) error {
	caller := std.PreviousRealm().Address()
	if !isApprovedOrOwner(caller, tid) {
		return grc721.ErrCallerIsNotOwnerOrApproved
	}

	err := transfer(from, to, tid)
	if err != nil {
		return err
	}

	// if !checkOnGRC721Received(from, to, tid) {
	// 	return ErrTransferToNonGRC721Receiver
	// }

	return nil
}

// Transfers `tokenId` token from `from` to `to`.
func iTransferFrom(from, to std.Address, tid grc721.TokenID) error {
	caller := std.PreviousRealm().Address()
	if !isApprovedOrOwner(caller, tid) {
		return grc721.ErrCallerIsNotOwnerOrApproved
	}

	err := transfer(from, to, tid)
	if err != nil {
		return err
	}

	return nil
}

// Mints `tokenId` and transfers it to `to`.
func iMint(to std.Address, tid grc721.TokenID) error {
	return mint(to, tid)
}

// Mints `tokenId` and transfers it to `to`. Also checks that
// contract recipients are using GRC721 protocol
func iSafeMint(to std.Address, tid grc721.TokenID) error {
	err := mint(to, tid)
	if err != nil {
		return err
	}

	// if !checkOnGRC721Received(zeroAddress, to, tid) {
	// 	return ErrTransferToNonGRC721Receiver
	// }

	return nil
}

func iBurn(tid grc721.TokenID) error {
	owner, err := iOwnerOf(tid)
	if err != nil {
		return err
	}

	// beforeTokenTransfer(owner, zeroAddress, tid, 1)

	(*tokenApprovals).Remove(string(tid))
	balance, err := iBalanceOf(owner)
	if err != nil {
		return err
	}
	balance -= 1
	(*balances).Set(owner.String(), balance)
	(*owners).Remove(string(tid))

	std.Emit(
		grc721.BurnEvent,
		"from", string(owner),
		"tokenId", string(tid),
	)

	// afterTokenTransfer(owner, zeroAddress, tid, 1)

	return nil
}

/* Helper methods */

// Helper for SetApprovalForAll()
func setApprovalForAll(owner, operator std.Address, approved bool) error {
	if owner == operator {
		return grc721.ErrApprovalToCurrentOwner
	}

	key := owner.String() + ":" + operator.String()
	(*operatorApprovals).Set(key, approved)

	std.Emit(
		grc721.ApprovalForAllEvent,
		"owner", string(owner),
		"to", string(operator),
		"approved", strconv.FormatBool(approved),
	)

	return nil
}

// Helper for TransferFrom() and SafeTransferFrom()
func transfer(from, to std.Address, tid grc721.TokenID) error {
	if err := isValidAddress(from); err != nil {
		return grc721.ErrInvalidAddress
	}
	if err := isValidAddress(to); err != nil {
		return grc721.ErrInvalidAddress
	}

	if from == to {
		return grc721.ErrCannotTransferToSelf
	}

	owner, err := iOwnerOf(tid)
	if err != nil {
		return err
	}
	if owner != from {
		return grc721.ErrTransferFromIncorrectOwner
	}

	// beforeTokenTransfer(from, to, tid, 1)

	// Check that tokenId was not transferred by `beforeTokenTransfer`
	owner, err = iOwnerOf(tid)
	if err != nil {
		return err
	}
	if owner != from {
		return grc721.ErrTransferFromIncorrectOwner
	}

	(*tokenApprovals).Remove(string(tid))
	fromBalance, err := iBalanceOf(from)
	if err != nil {
		return err
	}
	toBalance, err := iBalanceOf(to)
	if err != nil {
		return err
	}
	fromBalance -= 1
	toBalance += 1
	(*balances).Set(from.String(), fromBalance)
	(*balances).Set(to.String(), toBalance)
	(*owners).Set(string(tid), to)

	std.Emit(
		grc721.TransferEvent,
		"from", string(from),
		"to", string(to),
		"tokenId", string(tid),
	)

	// afterTokenTransfer(from, to, tid, 1)

	return nil
}

// Helper for Mint() and SafeMint()
func mint(to std.Address, tid grc721.TokenID) error {
	if err := isValidAddress(to); err != nil {
		return err
	}

	if exists(tid) {
		return grc721.ErrTokenIdAlreadyExists
	}

	// beforeTokenTransfer(zeroAddress, to, tid, 1)

	// Check that tokenId was not minted by `beforeTokenTransfer`
	if exists(tid) {
		return grc721.ErrTokenIdAlreadyExists
	}

	toBalance, err := iBalanceOf(to)
	if err != nil {
		return err
	}
	toBalance += 1
	(*balances).Set(to.String(), toBalance)
	(*owners).Set(string(tid), to)

	std.Emit(
		grc721.MintEvent,
		"to", string(to),
		"tokenId", string(tid),
	)

	// afterTokenTransfer(zeroAddress, to, tid, 1)

	return nil
}

func isApprovedOrOwner(addr std.Address, tid grc721.TokenID) bool {
	owner, found := (*owners).Get(string(tid))
	if !found {
		return false
	}

	if addr == owner.(std.Address) || iIsApprovedForAll(owner.(std.Address), addr) {
		return true
	}

	approved, err := iGetApproved(tid)
	if err != nil {
		return false
	}

	return approved == addr
}

// Checks if token id already exists
func exists(tid grc721.TokenID) bool {
	_, found := (*owners).Get(string(tid))
	return found
}

// func beforeTokenTransfer(from, to std.Address, firstTokenId grc721.TokenID, batchSize uint64) {
// 	// TODO: Implementation
// }

// func afterTokenTransfer(from, to std.Address, firstTokenId grc721.TokenID, batchSize uint64) {
// 	// TODO: Implementation
// }

// func checkOnGRC721Received(from, to std.Address, tid grc721.TokenID) bool {
// 	// TODO: Implementation
// 	return true
// }

func iRenderHome() (str string) {
	str += ufmt.Sprintf("# %s ($%s)\n\n", *name, *symbol)
	str += ufmt.Sprintf("* **Total supply**: %d\n", TokenCount())
	str += ufmt.Sprintf("* **Known accounts**: %d\n", (*balances).Size())

	return
}
