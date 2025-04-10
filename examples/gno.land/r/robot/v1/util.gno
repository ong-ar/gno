package v1

import (
	"std"
)

var zeroAddress = std.Address("")

func isValidAddress(addr std.Address) error {
	if !addr.IsValid() {
		return ErrInvalidAddress
	}
	return nil
}

func emit(event any) {
	// TODO: setup a pubsub system here?
}

func assertIsAdmin(address std.Address) {
	if address != admin {
		panic("restricted access")
	}
}

func assertIsLive() {
	if !isLive {
		panic("not live")
	}
}