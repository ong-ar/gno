package main

import (
	"std"
	"testing"
	"gno.land/p/demo/grc/grc721"
	"gno.land/p/demo/testutils"

	v1 "gno.land/r/robot/v1"
	v2 "gno.land/r/robot/v2"
)

var (
	admin = std.Address("g1u4pzrdsnhqd3cypet5qtrk6cdtftxdzd5297fx")

	test1Addr = testutils.TestAddress("test1Addr")
	test2Addr = testutils.TestAddress("test2Addr")
)

func expectPanic(f func(), msg string) {
	defer func() {
		if r := recover(); r == nil {
			println(msg, "-", "ok")
		} else {
			println(msg, "-", r)
		}
	}()
	f()
}

func changeCaller(addr std.Address) {
	println("Caller", "-", std.OriginCaller(), "to", addr)
	testing.SetOriginCaller(addr)
}

func main() {
	testing.SetOriginCaller(test2Addr)

	println("admin", "-", admin)
	println("test1Addr", "-", test1Addr)
	println("test2Addr", "-", test2Addr)

	// v1
	println("v1.Name()", "-", v1.Name())
	println("v1.Symbol()", "-", v1.Symbol())
	println("v1.TokenCount()", "-", v1.TokenCount())

	expectPanic(func() {
		v1.Mint(admin, grc721.TokenID("0"))
	}, `v1.Mint(admin, grc721.TokenID("0"))`)

	expectPanic(func() {
		v1.SetLive(true)
	}, `v1.SetLive(true)`)

	changeCaller(admin)

	expectPanic(func() {
		v1.SetLive(true)
	}, `v1.SetLive(true)`)

	expectPanic(func() {
		v1.Mint(admin, grc721.TokenID("0"))
	}, `v1.Mint(admin, grc721.TokenID("0"))`)

	expectPanic(func() {
		v1.Mint(admin, grc721.TokenID("0"))
	}, `v1.Mint(admin, grc721.TokenID("0"))`)

	expectPanic(func() {
		v1.Mint(admin, grc721.TokenID("1"))
	}, `v1.Mint(admin, grc721.TokenID("1"))`)

	expectPanic(func() {
		v1.Mint(admin, grc721.TokenID("2"))
	}, `v1.Mint(admin, grc721.TokenID("2"))`)

	expectPanic(func() {
		v1.Mint(test1Addr, grc721.TokenID("3"))
	}, `v1.Mint(test1Addr, grc721.TokenID("3"))`)

	expectPanic(func() {
		v1.Mint(test1Addr, grc721.TokenID("4"))
	}, `v1.Mint(test1Addr, grc721.TokenID("4"))`)

	expectPanic(func() {
		v1.Mint(test1Addr, grc721.TokenID("4"))
	}, `v1.Mint(test1Addr, grc721.TokenID("4"))`)

	expectPanic(func() {
		v1.Mint(test1Addr, grc721.TokenID("5"))
	}, `v1.Mint(test1Addr, grc721.TokenID("5"))`)

	expectPanic(func() {
		v1.Mint(test2Addr, grc721.TokenID("6"))
	}, `v1.Mint(test2Addr, grc721.TokenID("6"))`)
	
	expectPanic(func() {
		v1.Mint(test2Addr, grc721.TokenID("7"))
	}, `v1.Mint(test2Addr, grc721.TokenID("7"))`)

	expectPanic(func() {
		v1.Mint(test2Addr, grc721.TokenID("8"))
	}, `v1.Mint(test2Addr, grc721.TokenID("8"))`)

	expectPanic(func() {
		v1.Mint(test2Addr, grc721.TokenID("8"))
	}, `v1.Mint(test2Addr, grc721.TokenID("8"))`)

	changeCaller(test1Addr)

	// println("Caller", "-", std.OriginCaller(), "to", test1Addr)
	// testing.SetOriginCaller(test1Addr)

	expectPanic(func() {
		v1.Mint(test2Addr, grc721.TokenID("9"))
	}, `v1.Mint(test2Addr, grc721.TokenID("9"))`)

	println("v1.BalanceOf(admin)", "-", v1.BalanceOf(admin))
	println("v1.BalanceOf(test1Addr)", "-", v1.BalanceOf(test1Addr))
	println("v1.BalanceOf(test2Addr)", "-", v1.BalanceOf(test2Addr))
	println("v1.TokenCount()", "-", v1.TokenCount())

	println(`v1.OwnerOf(grc721.TokenID("0"))`, "-", v1.OwnerOf(grc721.TokenID("0")))
	println(`v1.OwnerOf(grc721.TokenID("1"))`, "-", v1.OwnerOf(grc721.TokenID("1")))
	println(`v1.OwnerOf(grc721.TokenID("2"))`, "-", v1.OwnerOf(grc721.TokenID("2")))
	println(`v1.OwnerOf(grc721.TokenID("3"))`, "-", v1.OwnerOf(grc721.TokenID("3")))
	println(`v1.OwnerOf(grc721.TokenID("4"))`, "-", v1.OwnerOf(grc721.TokenID("4")))
	println(`v1.OwnerOf(grc721.TokenID("5"))`, "-", v1.OwnerOf(grc721.TokenID("5")))
	println(`v1.OwnerOf(grc721.TokenID("6"))`, "-", v1.OwnerOf(grc721.TokenID("6")))
	println(`v1.OwnerOf(grc721.TokenID("7"))`, "-", v1.OwnerOf(grc721.TokenID("7")))
	println(`v1.OwnerOf(grc721.TokenID("8"))`, "-", v1.OwnerOf(grc721.TokenID("8")))

	expectPanic(func() {
		v1.OwnerOf(grc721.TokenID("9"))
	}, `v1.OwnerOf(grc721.TokenID("9"))`)

	changeCaller(admin)

	expectPanic(func() {
		v1.Burn(grc721.TokenID("2"))
	}, `v1.Burn(grc721.TokenID("2"))`)

	expectPanic(func() {
		v1.Burn(grc721.TokenID("5"))
	}, `v1.Burn(grc721.TokenID("5"))`)

	expectPanic(func() {
		v1.Burn(grc721.TokenID("8"))
	}, `v1.Burn(grc721.TokenID("8"))`)

	// v2
	println("v2.Name()", "-", v2.Name())
	println("v2.Symbol()", "-", v2.Symbol())
	println("v1.TokenCount()", "-", v1.TokenCount())

	println("v2.BalanceOf(admin)", "-", v2.BalanceOf(admin))
	println("v2.BalanceOf(test1Addr)", "-", v2.BalanceOf(test1Addr))
	println("v2.BalanceOf(test2Addr)", "-", v2.BalanceOf(test2Addr))

	println(`v2.OwnerOf(grc721.TokenID("0"))`, "-", v2.OwnerOf(grc721.TokenID("0")))
	println(`v2.OwnerOf(grc721.TokenID("1"))`, "-", v2.OwnerOf(grc721.TokenID("1")))

	expectPanic(func() {
		v2.OwnerOf(grc721.TokenID("2"))
	}, `v2.OwnerOf(grc721.TokenID("2"))`)

	println(`v2.OwnerOf(grc721.TokenID("3"))`, "-", v2.OwnerOf(grc721.TokenID("3")))
	println(`v2.OwnerOf(grc721.TokenID("4"))`, "-", v2.OwnerOf(grc721.TokenID("4")))

	expectPanic(func() {
		v2.OwnerOf(grc721.TokenID("5"))
	}, `v2.OwnerOf(grc721.TokenID("5"))`)

	println(`v2.OwnerOf(grc721.TokenID("6"))`, "-", v2.OwnerOf(grc721.TokenID("6")))
	println(`v2.OwnerOf(grc721.TokenID("7"))`, "-", v2.OwnerOf(grc721.TokenID("7")))

	expectPanic(func() {
		v2.OwnerOf(grc721.TokenID("8"))
	}, `v2.OwnerOf(grc721.TokenID("8"))`)

	expectPanic(func() {
		v2.OwnerOf(grc721.TokenID("9"))
	}, `v2.OwnerOf(grc721.TokenID("9"))`)

	println("done")
}

// Output:
// admin - g1u4pzrdsnhqd3cypet5qtrk6cdtftxdzd5297fx
// test1Addr - g1w3jhxap3g9jxgujlta047h6lta047h6lngk2jx
// test2Addr - g1w3jhxapjg9jxgujlta047h6lta047h6lmn8a4d
// v1.Name() - TestNFTv1
// v1.Symbol() - TNFT
// v1.TokenCount() - 0
// v1.Mint(admin, grc721.TokenID("0")) - current version is not live
// v1.SetLive(true) - restricted access
// Caller - g1w3jhxapjg9jxgujlta047h6lta047h6lmn8a4d to g1u4pzrdsnhqd3cypet5qtrk6cdtftxdzd5297fx
// v1.SetLive(true) - ok
// v1.Mint(admin, grc721.TokenID("0")) - ok
// v1.Mint(admin, grc721.TokenID("0")) - token id already exists
// v1.Mint(admin, grc721.TokenID("1")) - ok
// v1.Mint(admin, grc721.TokenID("2")) - ok
// v1.Mint(test1Addr, grc721.TokenID("3")) - ok
// v1.Mint(test1Addr, grc721.TokenID("4")) - ok
// v1.Mint(test1Addr, grc721.TokenID("4")) - token id already exists
// v1.Mint(test1Addr, grc721.TokenID("5")) - ok
// v1.Mint(test2Addr, grc721.TokenID("6")) - ok
// v1.Mint(test2Addr, grc721.TokenID("7")) - ok
// v1.Mint(test2Addr, grc721.TokenID("8")) - ok
// v1.Mint(test2Addr, grc721.TokenID("8")) - token id already exists
// Caller - g1u4pzrdsnhqd3cypet5qtrk6cdtftxdzd5297fx to g1w3jhxap3g9jxgujlta047h6lta047h6lngk2jx
// v1.Mint(test2Addr, grc721.TokenID("9")) - restricted access
// v1.BalanceOf(admin) - 3
// v1.BalanceOf(test1Addr) - 3
// v1.BalanceOf(test2Addr) - 3
// v1.TokenCount() - 9
// v1.OwnerOf(grc721.TokenID("0")) - g1u4pzrdsnhqd3cypet5qtrk6cdtftxdzd5297fx
// v1.OwnerOf(grc721.TokenID("1")) - g1u4pzrdsnhqd3cypet5qtrk6cdtftxdzd5297fx
// v1.OwnerOf(grc721.TokenID("2")) - g1u4pzrdsnhqd3cypet5qtrk6cdtftxdzd5297fx
// v1.OwnerOf(grc721.TokenID("3")) - g1w3jhxap3g9jxgujlta047h6lta047h6lngk2jx
// v1.OwnerOf(grc721.TokenID("4")) - g1w3jhxap3g9jxgujlta047h6lta047h6lngk2jx
// v1.OwnerOf(grc721.TokenID("5")) - g1w3jhxap3g9jxgujlta047h6lta047h6lngk2jx
// v1.OwnerOf(grc721.TokenID("6")) - g1w3jhxapjg9jxgujlta047h6lta047h6lmn8a4d
// v1.OwnerOf(grc721.TokenID("7")) - g1w3jhxapjg9jxgujlta047h6lta047h6lmn8a4d
// v1.OwnerOf(grc721.TokenID("8")) - g1w3jhxapjg9jxgujlta047h6lta047h6lmn8a4d
// v1.OwnerOf(grc721.TokenID("9")) - invalid token id
// Caller - g1w3jhxap3g9jxgujlta047h6lta047h6lngk2jx to g1u4pzrdsnhqd3cypet5qtrk6cdtftxdzd5297fx
// v1.Burn(grc721.TokenID("2")) - ok
// v1.Burn(grc721.TokenID("5")) - ok
// v1.Burn(grc721.TokenID("8")) - ok
// v2.Name() - TestNFTv2
// v2.Symbol() - TNFT
// v1.TokenCount() - 6
// v2.BalanceOf(admin) - 2
// v2.BalanceOf(test1Addr) - 2
// v2.BalanceOf(test2Addr) - 2
// v2.OwnerOf(grc721.TokenID("0")) - g1u4pzrdsnhqd3cypet5qtrk6cdtftxdzd5297fx
// v2.OwnerOf(grc721.TokenID("1")) - g1u4pzrdsnhqd3cypet5qtrk6cdtftxdzd5297fx
// v2.OwnerOf(grc721.TokenID("2")) - invalid token id
// v2.OwnerOf(grc721.TokenID("3")) - g1w3jhxap3g9jxgujlta047h6lta047h6lngk2jx
// v2.OwnerOf(grc721.TokenID("4")) - g1w3jhxap3g9jxgujlta047h6lta047h6lngk2jx
// v2.OwnerOf(grc721.TokenID("5")) - invalid token id
// v2.OwnerOf(grc721.TokenID("6")) - g1w3jhxapjg9jxgujlta047h6lta047h6lmn8a4d
// v2.OwnerOf(grc721.TokenID("7")) - g1w3jhxapjg9jxgujlta047h6lta047h6lmn8a4d
// v2.OwnerOf(grc721.TokenID("8")) - invalid token id
// v2.OwnerOf(grc721.TokenID("9")) - invalid token id
// done