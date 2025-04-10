package v2

import (
	"std"
)

var (
	admin std.Address = "g1u4pzrdsnhqd3cypet5qtrk6cdtftxdzd5297fx"
	isLive bool = false
	test = NewNFT("TestNFT", "TNFT", "v2")
)
// Getters

func BalanceOf(user std.Address) uint64 {
	balance, err := test.BalanceOf(user)
	if err != nil {
		panic(err)
	}

	return balance
}

func OwnerOf(tid TokenID) std.Address {
	owner, err := test.OwnerOf(tid)
	if err != nil {
		panic(err)
	}

	return owner
}

func IsApprovedForAll(owner, user std.Address) bool {
	return test.IsApprovedForAll(owner, user)
}

func GetApproved(tid TokenID) std.Address {
	addr, err := test.GetApproved(tid)
	if err != nil {
		panic(err)
	}

	return addr
}

// Setters

func Approve(user std.Address, tid TokenID) {
	err := test.Approve(user, tid)
	if err != nil {
		panic(err)
	}
}

func SetApprovalForAll(user std.Address, approved bool) {
	err := test.SetApprovalForAll(user, approved)
	if err != nil {
		panic(err)
	}
}

func TransferFrom(from, to std.Address, tid TokenID) {
	err := test.TransferFrom(from, to, tid)
	if err != nil {
		panic(err)
	}
}

// Admin

func Mint(to std.Address, tid TokenID) {
	caller := std.PreviousRealm().Address()
	assertIsAdmin(caller)
	err := test.Mint(to, tid)
	if err != nil {
		panic(err)
	}
}

func Burn(tid TokenID) {
	caller := std.PreviousRealm().Address()
	assertIsAdmin(caller)
	err := test.Burn(tid)
	if err != nil {
		panic(err)
	}
}

func SetLive(live bool) {
	caller := std.PreviousRealm().Address()
	assertIsAdmin(caller)
	isLive = live
}

// Render

func Render(path string) string {
	switch {
	case path == "":
		return test.RenderHome()
	default:
		return "404\n"
	}
}


// getter
func getBalance(addr std.Address) (any, bool) {
	return test.getBalance(addr)
}

func getOwner(tid TokenID) (any, bool) {
	return test.getOwner(tid)
}

func getBurnedOwner(tid TokenID) (any, bool) {
	return test.getBurnedOwner(tid)
}

func getTokenURI(tid TokenID) (any, bool) {
	return test.getTokenURI(tid)
}

func getOperatorApproval(key string) (any, bool) {
	return test.getOperatorApproval(key)
}

func getTokenApproval(tid TokenID) (any, bool) {
	return test.getTokenApproval(tid)
}

