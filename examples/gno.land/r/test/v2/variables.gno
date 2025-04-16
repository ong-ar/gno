package v2

import (
	"std"

	"gno.land/p/demo/avl"
	v1 "gno.land/r/test/v1"
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
	prevName, prevSymbol, prevOwners, prevBalances, prevTokenApprovals, prevTokenURIs, prevOperatorApprovals := v1.GetRefs()

	name = prevName
	symbol = prevSymbol
	owners = prevOwners
	balances = prevBalances
	tokenApprovals = prevTokenApprovals
	tokenURIs = prevTokenURIs
	operatorApprovals = prevOperatorApprovals

	previousRealmPkgPath = ""
	admin = std.Address("g1u4pzrdsnhqd3cypet5qtrk6cdtftxdzd5297fx")
}

// external methods
func GetRefs() (*string, *string, *avl.Tree, *avl.Tree, *avl.Tree, *avl.Tree, *avl.Tree) {
	println(std.PreviousRealm().PkgPath())
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