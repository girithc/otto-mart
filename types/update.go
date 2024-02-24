package types

type UpdateApp struct {
	PackageName string `json:"package_name"`
	Verion      string `json:"version"`
	BuildNo     string `json:"build_no"`
	PlatForm    string `json:"platform"`
}
