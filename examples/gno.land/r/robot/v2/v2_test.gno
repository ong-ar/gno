package v2

import (
	"std"
	"fmt"
	"testing"

	"gno.land/p/demo/testutils"
	"gno.land/p/demo/grc/grc721"
	v1 "gno.land/r/robot/v1"
)

func TestV1(t *testing.T) {
	admin := std.Address("g1u4pzrdsnhqd3cypet5qtrk6cdtftxdzd5297fx")

	test1Addr := testutils.TestAddress("test1Addr")
	test2Addr := testutils.TestAddress("test2Addr")

	// Mint(admin, grc721.TokenID("0"))
	// Mint(test1Addr, grc721.TokenID("1"))

	for _, tc := range []struct {
		name     string
		expected any
		isPanic    bool
		fn       func() any
	}{
		{`Mint(admin, grc721.TokenID("0"))`, "restricted access", true, func() any { 
			Mint(admin, grc721.TokenID("0"))
			return nil 
		}},
		{`testing.SetOriginCaller(admin)`, nil, true, func() any { 
			testing.SetOriginCaller(admin)
			return nil 
		}},
		{`Mint(admin, grc721.TokenID("0"))`, "current version is not live", true, func() any { 
			Mint(admin, grc721.TokenID("0"))
			return nil 
		}},
		{`SetLive(true)`, nil, true, func() any { 
			SetLive(true)
			return nil 
		}},
		{`Mint(admin->0,1,2)(test1Addr->3,4,5)(test2Addr->6,7,8)`, nil, true, func() any { 
			Mint(admin, grc721.TokenID("0"))
			Mint(admin, grc721.TokenID("1"))
			Mint(admin, grc721.TokenID("2"))
			Mint(test1Addr, grc721.TokenID("3"))
			Mint(test1Addr, grc721.TokenID("4"))
			Mint(test1Addr, grc721.TokenID("5"))
			Mint(test2Addr, grc721.TokenID("6"))
			Mint(test2Addr, grc721.TokenID("7"))
			Mint(test2Addr, grc721.TokenID("8"))
			return nil 
		}},
		{`Mint(test2Addr, grc721.TokenID("8"))`, "token id already exists", true, func() any { 
			Mint(test2Addr, grc721.TokenID("8"))
			return nil 
		}},
		{`TransferFrom(test1Addr, test2Addr, grc721.TokenID("3"))`, "caller is not token owner or approved", true, func() any { 
			TransferFrom(test1Addr, test2Addr, grc721.TokenID("3"))
			return nil 
		}},
		{`testing.SetOriginCaller(test1Addr)`, nil, true, func() any { 
			testing.SetOriginCaller(test1Addr)
			return nil 
		}},
		{`TransferFrom(test1Addr, test2Addr, grc721.TokenID("3"))`, nil, true, func() any { 
			TransferFrom(test1Addr, test2Addr, grc721.TokenID("3"))
			return nil
		}},
		{`Approve(test2Addr, grc721.TokenID("0"))`, "caller is not token owner or approved", true, func() any { 
			Approve(test2Addr, grc721.TokenID("0"))
			return nil 
		}},
		{`Approve(test2Addr, grc721.TokenID("4"))`, nil, true, func() any { 
			Approve(test2Addr, grc721.TokenID("4"))
			return nil 
		}},
		{`testing.SetOriginCaller(test2Addr)`, nil, true, func() any { 
			testing.SetOriginCaller(test2Addr)
			return nil 
		}},
		{`TransferFrom(test1Addr, test2Addr, grc721.TokenID("4"))`, nil, true, func() any { 
			TransferFrom(test1Addr, test2Addr, grc721.TokenID("4"))
			return nil
		}},
		{`SetApprovalForAll(test1Addr, true)`, nil, true, func() any { 
			SetApprovalForAll(test1Addr, true)
			return nil
		}},
		{`IsApprovedForAll(test2Addr, test1Addr)`, true, false, func() any { 
			return IsApprovedForAll(test2Addr, test1Addr)
		}},
		{`testing.SetOriginCaller(test1Addr)`, nil, true, func() any { 
			testing.SetOriginCaller(test1Addr)
			return nil 
		}},
		{`TransferFrom(test2Addr, test1Addr, grc721.TokenID("6"))`, nil, true, func() any { 
			TransferFrom(test2Addr, test1Addr, grc721.TokenID("6"))
			return nil 
		}},
		{`TransferFrom(test2Addr, test1Addr, grc721.TokenID("7"))`, nil, true, func() any { 
			TransferFrom(test2Addr, test1Addr, grc721.TokenID("7"))
			return nil 
		}},
		{`OwnerOf(grc721.TokenID("0"))`, admin, false, func() any { 
			return OwnerOf(grc721.TokenID("0"))
		}},
		{`OwnerOf(grc721.TokenID("1"))`, admin, false, func() any { 
			return OwnerOf(grc721.TokenID("1"))
		}},
		{`OwnerOf(grc721.TokenID("2"))`, admin, false, func() any { 
			return OwnerOf(grc721.TokenID("2"))
		}},
		{`OwnerOf(grc721.TokenID("3"))`, test2Addr, false, func() any { 
			return OwnerOf(grc721.TokenID("3"))
		}},
		{`OwnerOf(grc721.TokenID("4"))`, test2Addr, false, func() any { 
			return OwnerOf(grc721.TokenID("4"))
		}},
		{`OwnerOf(grc721.TokenID("5"))`, test1Addr, false, func() any { 
			return OwnerOf(grc721.TokenID("5"))
		}},
		{`OwnerOf(grc721.TokenID("6"))`, test1Addr, false, func() any { 
			return OwnerOf(grc721.TokenID("6"))
		}},
		{`OwnerOf(grc721.TokenID("7"))`, test1Addr, false, func() any { 
			return OwnerOf(grc721.TokenID("7"))
		}},
		{`OwnerOf(grc721.TokenID("8"))`, test2Addr, false, func() any { 
			return OwnerOf(grc721.TokenID("8"))
		}},
		{`BalanceOf(admin)`, uint64(3), false, func() any { 
			return BalanceOf(admin)
		}},
		{`BalanceOf(test1Addr)`, uint64(3), false, func() any { 
			return BalanceOf(test1Addr)
		}},
		{`BalanceOf(test2Addr)`, uint64(3), false, func() any { 
			return BalanceOf(test2Addr)
		}},
		{`Burn(grc721.TokenID("8"))`, "restricted access", true, func() any { 
			Burn(grc721.TokenID("8"))
			return nil
		}},
		{`testing.SetOriginCaller(admin)`, nil, true, func() any { 
			testing.SetOriginCaller(admin)
			return nil 
		}},
		{`Burn(grc721.TokenID("8"))`, nil, true, func() any { 
			Burn(grc721.TokenID("8"))
			return nil
		}},
		{`OwnerOf(grc721.TokenID("8"))`, "invalid token id", true, func() any { 
			OwnerOf(grc721.TokenID("8"))
			return nil
		}},
		{`SetLive(false)`, nil, true, func() any { 
			SetLive(false)
			return nil
		}},
		{`Approve(test1Addr, grc721.TokenID("0"))`, "current version is not live", true, func() any { 
			Approve(test1Addr, grc721.TokenID("0"))
			return nil 
		}},
		{`Mint(admin, grc721.TokenID("9"))`, "current version is not live", true, func() any { 
			Mint(admin, grc721.TokenID("9"))
			return nil 
		}},
		{`SetApprovalForAll(test1Addr, true)`, "current version is not live", true, func() any { 
			SetApprovalForAll(test1Addr, true)
			return nil 
		}},
		{`TransferFrom(admin, test1Addr, grc721.TokenID("0"))`, "current version is not live", true, func() any { 
			TransferFrom(admin, test1Addr, grc721.TokenID("0"))
			return nil 
		}},
		{`TokenCount()`, uint64(8), false, func() any { 
			return TokenCount()
		}},

	} {
		t.Run(tc.name, func(t *testing.T) {
			defer func() {
				if r := recover(); r != nil {
					if !tc.isPanic {
						t.Errorf("    unexpected panic: %v", r)
						return
					}
	
					gotMsg := fmt.Sprintf("%v", r)
					expectedMsg, ok := tc.expected.(string)
					if !ok {
						t.Errorf("    panic occurred but expected is not a string: %v", tc.expected)
						return
					}
	
					if gotMsg != expectedMsg {
						t.Errorf("    expected panic message %q, got %q", expectedMsg, gotMsg)
					} else {
						t.Logf("    recovered from expected panic: %q", gotMsg)
					}
				}
			}()
	
			got := tc.fn()
	
			if !tc.isPanic && got != tc.expected {
				t.Errorf("    expected: %v, got: %v", tc.expected, got)
			}
		})
	}
}

