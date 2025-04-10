package v1

type (
	TokenID  string
	TokenURI string
)

const (
	MintEvent           = "Mint"
	BurnEvent           = "Burn"
	TransferEvent       = "Transfer"
	ApprovalEvent       = "Approval"
	ApprovalForAllEvent = "ApprovalForAll"
)
