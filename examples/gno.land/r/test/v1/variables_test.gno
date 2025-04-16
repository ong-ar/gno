package v1

import (
	"std"
	"testing"
)

func TestVariables(t *testing.T) {
	admin := std.Address("g1u4pzrdsnhqd3cypet5qtrk6cdtftxdzd5297fx")
	previousRealmPkgPath := "gno.land/r/test/v2"

	t.Run("TestVariables", func(t *testing.T) {
		defer func() {
			if r := recover(); r != nil {
				t.Errorf("recovered from panic: %v", r)
			}
		}()

		testing.SetOriginCaller(admin)

		SetPreviousRealmPkgPath(previousRealmPkgPath)
	
		testing.SetRealm(std.NewCodeRealm(previousRealmPkgPath))

		GetRefs()
	})
}

