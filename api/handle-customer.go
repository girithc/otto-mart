package api

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/girithc/pronto-go/types"

	"github.com/golang-jwt/jwt/v4"
)

// Define your secret key for JWT
var jwtKey = []byte("my_secret_key")

func (s *Server) Handle_Customer_Login(res http.ResponseWriter, req *http.Request) error {
	// Preprocessing

	new_req := new(types.Create_Customer)

	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in Handle_User_Login()")
		return err
	}

	new_user, err := types.New_Customer(new_req.Phone)
	fmt.Println(new_user.Phone)

	if err != nil {
		return err
	}

	// Check if User Exists

	user, err := s.store.Get_Customer_By_Phone(new_user.Phone)
	if err != nil {
		return err
	}

	// User Does Not Exist
	if user == nil {
		fmt.Println("User Does Not Exist")

		user, err := s.store.Create_Customer(new_req)
		if err != nil {
			return err
		}

		fmt.Println("Shopping Cart Created ", user.Cart_Id)

		// Generate JWT token
		tokenString, err := generateJWT(strconv.Itoa(user.Phone))
		if err != nil {
			return err
		}

		// Set the JWT token as a cookie
		expirationTime := time.Now().Add(1 * time.Hour)
		http.SetCookie(res, &http.Cookie{
			Name:    "token",
			Value:   tokenString,
			Expires: expirationTime,
		})

		return WriteJSON(res, http.StatusOK, user)
	} else { // User Exists
		fmt.Println("User Exists")

		// Generate JWT token
		tokenString, err := generateJWT(strconv.Itoa(user.Phone))
		if err != nil {
			return err
		}

		// Set the JWT token as a cookie
		expirationTime := time.Now().Add(1 * time.Hour)
		http.SetCookie(res, &http.Cookie{
			Name:    "token",
			Value:   tokenString,
			Expires: expirationTime,
		})

		return WriteJSON(res, http.StatusOK, user)
	}
}

func (s *Server) Handle_Get_Customers(res http.ResponseWriter, req *http.Request) error {
	customers, err := s.store.Get_All_Customers()
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, customers)
}

// GenerateJWTToken generates a JWT token with the given username
func generateJWT(username string) (string, error) {
	token := jwt.New(jwt.SigningMethodHS256)
	claims := token.Claims.(jwt.MapClaims)

	claims["authorized"] = true
	claims["username"] = username
	claims["exp"] = time.Now().Add(time.Hour * 30).Unix()

	tokenString, err := token.SignedString(jwtKey)
	if err != nil {
		fmt.Printf("Something Went Wrong: %s", err.Error())
		return "", err
	}
	return tokenString, nil
}
