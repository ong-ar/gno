package v1

import (
	"fmt"
	"std"
	"testing"

	"gno.land/p/demo/grc/grc721"
	"gno.land/p/demo/testutils"
)

func TestGRC721(t *testing.T) {

	admin := std.Address("g1u4pzrdsnhqd3cypet5qtrk6cdtftxdzd5297fx")

	test1Addr := testutils.TestAddress("test1Addr")
	test2Addr := testutils.TestAddress("test2Addr")
	test3Addr := testutils.TestAddress("test3Addr")

	

	t.Run("Name()", func(t *testing.T) {
		expect := "TestNFT"
		name := Name()

		if name != expect {
			t.Errorf("expected %s, got %s", expect, name)
		}
	})

	t.Run("Symbol()", func(t *testing.T) {
		expect := "TNFT"
		symbol := Symbol()
		
		if symbol != expect {
			t.Errorf("expected %s, got %s", expect, name)
		}
	})

	t.Run("Mint() not admin caller", func(t *testing.T) {
		expect := "restricted access"
		defer func() {
			if r := recover(); r != nil && fmt.Sprintf("%v", r) != expect {
				t.Errorf("recovered from panic: %v", r)
			}
		}()
		Mint(test1Addr, grc721.TokenID("0"))
	})

	t.Run("Mint() admin caller", func(t *testing.T) {
		testing.SetOriginCaller(admin)

		Mint(admin, grc721.TokenID("0"))
		Mint(admin, grc721.TokenID("1"))
		Mint(admin, grc721.TokenID("2"))
		Mint(test1Addr, grc721.TokenID("3"))
		Mint(test1Addr, grc721.TokenID("4"))
		Mint(test1Addr, grc721.TokenID("5"))
		Mint(test2Addr, grc721.TokenID("6"))
		Mint(test2Addr, grc721.TokenID("7"))
		Mint(test2Addr, grc721.TokenID("8"))

		if BalanceOf(admin) != 3 {
			t.Errorf("expected 3, got %d", BalanceOf(admin))
		}
		if BalanceOf(test1Addr) != 3 {
			t.Errorf("expected 3, got %d", BalanceOf(test1Addr))
		}
		if BalanceOf(test2Addr) != 3 {
			t.Errorf("expected 3, got %d", BalanceOf(test2Addr))
		}

		if OwnerOf(grc721.TokenID("0")) != admin {
			t.Errorf("expected %s, got %s", admin, OwnerOf(grc721.TokenID("0")))
		}
		if OwnerOf(grc721.TokenID("1")) != admin {
			t.Errorf("expected %s, got %s", admin, OwnerOf(grc721.TokenID("1")))
		}
		if OwnerOf(grc721.TokenID("2")) != admin {
			t.Errorf("expected %s, got %s", admin, OwnerOf(grc721.TokenID("2")))
		}
		if OwnerOf(grc721.TokenID("3")) != test1Addr {
			t.Errorf("expected %s, got %s", test1Addr, OwnerOf(grc721.TokenID("3")))
		}
		if OwnerOf(grc721.TokenID("4")) != test1Addr {
			t.Errorf("expected %s, got %s", test1Addr, OwnerOf(grc721.TokenID("4")))
		}
		if OwnerOf(grc721.TokenID("5")) != test1Addr {
			t.Errorf("expected %s, got %s", test1Addr, OwnerOf(grc721.TokenID("5")))
		}
		if OwnerOf(grc721.TokenID("6")) != test2Addr {
			t.Errorf("expected %s, got %s", test2Addr, OwnerOf(grc721.TokenID("6")))
		}
		if OwnerOf(grc721.TokenID("7")) != test2Addr {
			t.Errorf("expected %s, got %s", test2Addr, OwnerOf(grc721.TokenID("7")))
		}
		if OwnerOf(grc721.TokenID("8")) != test2Addr {
			t.Errorf("expected %s, got %s", test2Addr, OwnerOf(grc721.TokenID("8")))
		}

		if TokenCount() != 9 {
			t.Errorf("expected 9, got %d", TokenCount())
		}

		Burn(grc721.TokenID("8"))

		if TokenCount() != 8 {
			t.Errorf("expected 8, got %d", TokenCount())
		}
		if BalanceOf(test2Addr) != 2 {
			t.Errorf("expected 2, got %d", BalanceOf(test2Addr))
		}
	})

	t.Run("TransferFrom() not owner caller", func(t *testing.T) {
		expect := "caller is not token owner or approved"
		defer func() {
			if r := recover(); r != nil && fmt.Sprintf("%v", r) != expect {
				t.Errorf("recovered from panic: %v", r)
			}
		}()
		
		TransferFrom(test2Addr, test1Addr, grc721.TokenID("6"))
	})

	t.Run("TransferFrom() owner caller", func(t *testing.T) {
		testing.SetOriginCaller(test2Addr)
		TransferFrom(test2Addr, test1Addr, grc721.TokenID("6"))

		if OwnerOf(grc721.TokenID("6")) != test1Addr {
			t.Errorf("expected %s, got %s", test1Addr, OwnerOf(grc721.TokenID("6")))
		}
		if BalanceOf(test2Addr) != 1 {
			t.Errorf("expected 1, got %d", BalanceOf(test2Addr))
		}
		if BalanceOf(test1Addr) != 4 {
			t.Errorf("expected 4, got %d", BalanceOf(test1Addr))
		}
		if TokenCount() != 8 {
			t.Errorf("expected 8, got %d", TokenCount())
		}
	})

	t.Run("Approve() not owner caller", func(t *testing.T) {
		expect := "caller is not token owner or approved"
		defer func() {
			if r := recover(); r != nil && fmt.Sprintf("%v", r) != expect {
				t.Errorf("recovered from panic: %v", r)
			}
		}()
		
		Approve(test2Addr, grc721.TokenID("6"))
	})

	t.Run("Approve() owner caller", func(t *testing.T) {
		testing.SetOriginCaller(test1Addr)
		Approve(test2Addr, grc721.TokenID("6"))

		if GetApproved(grc721.TokenID("6")) != test2Addr {
			t.Errorf("expected %s, got %s", test2Addr, GetApproved(grc721.TokenID("6")))
		}
	})

	t.Run("GetApproved()", func(t *testing.T) {
		addr := GetApproved(grc721.TokenID("6"))

		if addr != test2Addr {
			t.Errorf("expected %s, got %s", test2Addr, addr)
		}
	})

	t.Run("TransferFrom() approved caller", func(t *testing.T) {
		testing.SetOriginCaller(test2Addr)
		TransferFrom(test1Addr, test2Addr, grc721.TokenID("6"))

		if OwnerOf(grc721.TokenID("6")) != test2Addr {
			t.Errorf("expected %s, got %s", test2Addr, OwnerOf(grc721.TokenID("6")))
		}
		if BalanceOf(test2Addr) != 2 {
			t.Errorf("expected 2, got %d", BalanceOf(test2Addr))
		}
		if BalanceOf(test1Addr) != 3 {
			t.Errorf("expected 3, got %d", BalanceOf(test1Addr))
		}
		if TokenCount() != 8 {
			t.Errorf("expected 8, got %d", TokenCount())
		}
	})


	t.Run("SetApprovalForAll()", func(t *testing.T) {
		testing.SetOriginCaller(test1Addr)
		SetApprovalForAll(test2Addr, true)

		if !IsApprovedForAll(test1Addr, test2Addr) {
			t.Errorf("expected true, got false")
		}
	})

	// TransferFrom with approval
	t.Run("TransferFrom() approved for all caller", func(t *testing.T) {
		testing.SetOriginCaller(test2Addr)
		TransferFrom(test1Addr, test3Addr, grc721.TokenID("4"))

		if OwnerOf(grc721.TokenID("4")) != test3Addr {
			t.Errorf("expected %s, got %s", test3Addr, OwnerOf(grc721.TokenID("4")))
		}
		if BalanceOf(test2Addr) != 2 {
			t.Errorf("expected 1, got %d", BalanceOf(test2Addr))
		}
		if BalanceOf(test1Addr) != 2 {
			t.Errorf("expected 2, got %d", BalanceOf(test1Addr))
		}
		if TokenCount() != 8 {
			t.Errorf("expected 8, got %d", TokenCount())
		}
	})
}
