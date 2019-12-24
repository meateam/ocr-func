package function

import (
	"fmt"
	"net/http"

	handler "github.com/openfaas-incubator/go-function-sdk"
	"github.com/otiai10/gosseract"
)

// Handle a function invocation
func Handle(req handler.Request) (handler.Response, error) {
	if req.Body == nil {
		return handler.Response{
			StatusCode: http.StatusBadRequest,
		}, fmt.Errorf("request shouldnt be empty")
	}

	client := gosseract.NewClient()
	defer client.Close()

	if err := client.SetLanguage("eng", "heb", "ara", "fas"); err != nil {
		return handler.Response{
			StatusCode: http.StatusInternalServerError,
		}, err
	}

	if err := client.SetImageFromBytes(req.Body); err != nil {
		return handler.Response{
			StatusCode: http.StatusInternalServerError,
		}, err
	}

	message, err := client.Text()
	if err != nil {
		return handler.Response{
			StatusCode: http.StatusInternalServerError,
		}, err
	}

	return handler.Response{
		Body:       []byte(message),
		StatusCode: http.StatusOK,
	}, nil
}
