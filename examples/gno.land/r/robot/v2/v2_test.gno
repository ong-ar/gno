package v1

import (
	"std"
	"testing"

	"gno.land/p/demo/testutils"
)

func TestV1(t *testing.T) {
	admin := std.Address("g1u4pzrdsnhqd3cypet5qtrk6cdtftxdzd5297fx")

	test1Addr := testutils.TestAddress("test1Addr")
	test2Addr := testutils.TestAddress("test2Addr")

	testing.SetOriginCaller(admin)

	SetLive(true)

	Mint(admin, TokenID("0"))
	Mint(test1Addr, TokenID("1"))
	Mint(test2Addr, TokenID("2"))

	for _, tc := range []struct {
		name     string
		expected any
		fn       func() any
	}{
		{"BalanceOf(admin)", uint64(1), func() interface{} { return BalanceOf(admin) }},
		{"BalanceOf(test1Addr)", uint64(1), func() interface{} { return BalanceOf(test1Addr) }},
		{"BalanceOf(test2Addr)", uint64(1), func() interface{} { return BalanceOf(test2Addr) }},
		{"OwnerOf(0)", admin, func() interface{} { return OwnerOf(TokenID("0")) }},
		{"OwnerOf(1)", test1Addr, func() interface{} { return OwnerOf(TokenID("1")) }},
		{"OwnerOf(2)", test2Addr, func() interface{} { return OwnerOf(TokenID("2")) }},
	} {
		t.Run(tc.name, func(t *testing.T) {
			got := tc.fn()
			if tc.expected != got {
				t.Errorf("expected: %v got: %v", tc.expected, got)
			}
		})
	}
}

