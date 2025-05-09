package types

type UpdateApp struct {
	PackageName string `json:"package_name"`
	Version     string `json:"version"`
	BuildNo     string `json:"build_no"`
	Platform    string `json:"platform"`
}

type UpdateAppInput struct {
	PackageName string `json:"packageName"`
	Version     string `json:"version"`
	BuildNo     string `json:"buildNumber"`
	Platform    string `json:"platform"`
}
