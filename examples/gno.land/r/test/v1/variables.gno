package v1

import (
	"std"

	"gno.land/p/demo/avl"
)

const zeroAddress std.Address = ""

var (
	name                 *string
	symbol               *string
	owners               *avl.Tree // tokenId -> OwnerAddress
	balances             *avl.Tree // OwnerAddress -> TokenCount
	tokenApprovals       *avl.Tree // TokenId -> ApprovedAddress
	tokenURIs            *avl.Tree // TokenId -> URIs
	operatorApprovals    *avl.Tree // "OwnerAddress:OperatorAddress" -> bool

	previousRealmPkgPath string
	admin			     std.Address
)

func init() {
	nameString := "TestNFT"
	symbolString := "TNFT"

	name = &nameString
	symbol = &symbolString
	owners = &avl.Tree{}
	balances = &avl.Tree{}
	tokenApprovals = &avl.Tree{}
	tokenURIs = &avl.Tree{}
	operatorApprovals = &avl.Tree{}

	previousRealmPkgPath = "gno.land/r/test/v2"
	admin = std.Address("g1u4pzrdsnhqd3cypet5qtrk6cdtftxdzd5297fx")
}

// external methods
func GetRefs() (*string, *string, *avl.Tree, *avl.Tree, *avl.Tree, *avl.Tree, *avl.Tree) {
	println("v1", std.PreviousRealm().PkgPath())
	println("v1", std.PreviousRealm().Address())
	if previousRealmPkgPath == "" || previousRealmPkgPath != std.PreviousRealm().PkgPath() {
		panic("previous realm package path mismatch")
	}

	return name, symbol, owners, balances, tokenApprovals, tokenURIs, operatorApprovals
}

func SetPreviousRealmPkgPath(pkgPath string) {
	caller := std.PreviousRealm().Address()
	assertIsAdmin(caller)

	previousRealmPkgPath = pkgPath
}