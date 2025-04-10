package v1

import (
	"std"

	"gno.land/p/demo/grc/grc721"
)

var (
	nft = NewNFT("TestNFT", "TNFT", "v1")

	isLive bool = false
	admin std.Address = "g1u4pzrdsnhqd3cypet5qtrk6cdtftxdzd5297fx"
)

// func init() {
// 	nft.Mint("g1u4pzrdsnhqd3cypet5qtrk6cdtftxdzd5297fx", grc721.TokenID("0"))
// }

// Getters
func BalanceOf(user std.Address) uint64 {
	balance, err := nft.BalanceOf(user)
	if err != nil {
		panic(err)
	}

	return balance
}

func OwnerOf(tid grc721.TokenID) std.Address {
	owner, err := nft.OwnerOf(tid)
	if err != nil {
		panic(err)
	}

	return owner
}

func IsApprovedForAll(owner, user std.Address) bool {
	return nft.IsApprovedForAll(owner, user)
}

func GetApproved(tid grc721.TokenID) std.Address {
	addr, err := nft.GetApproved(tid)
	if err != nil {
		panic(err)
	}

	return addr
}

// Setters
func Approve(user std.Address, tid grc721.TokenID) {
	err := nft.Approve(user, tid)
	if err != nil {
		panic(err)
	}
}

func SetApprovalForAll(user std.Address, approved bool) {
	err := nft.SetApprovalForAll(user, approved)
	if err != nil {
		panic(err)
	}
}

func TransferFrom(from, to std.Address, tid grc721.TokenID) {
	err := nft.TransferFrom(from, to, tid)
	if err != nil {
		panic(err)
	}
}

// Admin
func Mint(to std.Address, tid grc721.TokenID) {
	caller := std.PreviousRealm().Address()
	println("caller", caller.String())
	assertIsAdmin(caller)

	err := nft.Mint(to, tid)
	if err != nil {
		panic(err)
	}
}

func Burn(tid grc721.TokenID) {
	caller := std.PreviousRealm().Address()
	assertIsAdmin(caller)

	err := nft.Burn(tid)
	if err != nil {
		panic(err)
	}
}

func SetLive(live bool) {
	caller := std.PreviousRealm().Address()
	assertIsAdmin(caller)

	isLive = live
}

func SetAdmin(addr std.Address) {
	caller := std.PreviousRealm().Address()
	assertIsAdmin(caller)

	admin = addr
}

// Render

func Render(path string) string {
	switch {
	case path == "":
		return nft.RenderHome()
	default:
		return "404\n"
	}
}


// getters for next version
func GetBalance(addr std.Address) (any, bool) {
	return nft.balances.Get(addr.String())
}

func GetOwner(tid grc721.TokenID) (any, bool) {
	return nft.getOwner(tid)
}

func GetBurnedOwner(tid grc721.TokenID) (any, bool) {
	return nft.getBurnedOwner(tid)
}

func GetTokenURI(tid grc721.TokenID) (any, bool) {
	return nft.getTokenURI(tid)
}

func GetOperatorApproval(key string) (any, bool) {
	return nft.getOperatorApproval(key)
}

func GetTokenApproval(tid grc721.TokenID) (any, bool) {
	return nft.getTokenApproval(tid)
}

// utils
func isValidAddress(addr std.Address) error {
	if !addr.IsValid() {
		return grc721.ErrInvalidAddress
	}
	return nil
}

func assertIsAdmin(address std.Address) {
	if address != admin {
		panic("restricted access")
	}
}

func assertIsLive() {
	if !isLive {
		panic("restricted access")
	}
}