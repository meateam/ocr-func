package function

import (
	"github.com/otiai10/gosseract"
)

// Handle a function invocation
func Handle(req []byte) string {
	if req == nil {
		return "empty body"
	}

	client := gosseract.NewClient()
	defer client.Close()

	if err := client.SetLanguage("eng", "heb", "ara", "fas"); err != nil {
		return err.Error()
	}

	if err := client.SetImageFromBytes(req.Body); err != nil {
		return err.Error()
	}

	message, err := client.Text()
	if err != nil {
		return err.Error()
	}

	return message
}
