package v2

import (
	"std"

	"gno.land/p/demo/grc/grc721"
)

var (
	nft = newNFT("TestNFT", "TNFT", "v2")

	isLive bool = false
	admin std.Address = std.Address("g1u4pzrdsnhqd3cypet5qtrk6cdtftxdzd5297fx")
)

// Getters
func Name() string {
	return nft.Name()
}

func Symbol() string {
	return nft.Symbol()
}

func Version() string {
	return nft.Version()
}

func TokenCount() uint64 {
	return nft.TokenCount()
}

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

func TokenIDsOf(user std.Address) []string {
	tokenIDs, err := nft.TokenIDsOf(user)
	if err != nil {
		panic(err)
	}

	return tokenIDs
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
	assertIsLive()
	err := nft.Approve(user, tid)
	if err != nil {
		panic(err)
	}
}

func SetApprovalForAll(user std.Address, approved bool) {
	assertIsLive()
	err := nft.SetApprovalForAll(user, approved)
	if err != nil {
		panic(err)
	}
}

func TransferFrom(from, to std.Address, tid grc721.TokenID) {
	assertIsLive()
	err := nft.TransferFrom(from, to, tid)
	if err != nil {
		panic(err)
	}
}

// Admin
func Mint(to std.Address, tid grc721.TokenID) {
	caller := std.PreviousRealm().Address()
	assertIsAdmin(caller)
	
	assertIsLive()

	err := nft.Mint(to, tid)
	if err != nil {
		panic(err)
	}
}

func Burn(tid grc721.TokenID) {
	caller := std.PreviousRealm().Address()
	assertIsAdmin(caller)

	assertIsLive()

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
func ZZ_GetBalance(addr std.Address) (any, bool) {
	return nft.ZZ_GetBalance(addr)
}

func ZZ_GetOwner(tid grc721.TokenID) (any, bool) {
	return nft.ZZ_GetOwner(tid)
}

func ZZ_GetBurnedOwner(tid grc721.TokenID) (any, bool) {
	return nft.ZZ_GetBurnedOwner(tid)
}

func ZZ_GetTokenURI(tid grc721.TokenID) (any, bool) {
	return nft.ZZ_GetTokenURI(tid)
}

func ZZ_GetOperatorApproval(key string) (any, bool) {
	return nft.ZZ_GetOperatorApproval(key)
}

func ZZ_GetTokenApproval(tid grc721.TokenID) (any, bool) {
	return nft.ZZ_GetTokenApproval(tid)
}

func ZZ_GetOwnedTokenIDs(addr std.Address) (any, bool) {
	return nft.ZZ_GetOwnedTokenIDs(addr)
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
		panic("current version is not live")
	}
}