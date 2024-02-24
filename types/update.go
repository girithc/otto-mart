package types

type UpdateApp struct {
	PackageName string `json:"package_name"`
	Version     string `json:"version"`
	BuildNo     string `json:"build_no"`
	Platform    string `json:"platform"`
}
