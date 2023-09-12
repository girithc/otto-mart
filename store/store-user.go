package store

import (
	"database/sql"
	"log"
	"pronto-go/types"
)


func (s *PostgresStore) Create_User_Table() error {
	//fmt.Println("Entered CreateHigherLevelCategoryTable")

	query := `create table if not exists user_ (
		id SERIAL PRIMARY KEY,
    	name VARCHAR(100) NOT NULL,
		phone INT NOT NULL,
		refresh_token TEXT,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	)`

	_, err := s.db.Exec(query)

	//fmt.Println("Exiting CreateHigherLevelCategoryTable")

	return err
}

func (s *PostgresStore) Create_User(user *types.Create_User) (*types.User, error) {
	
	
	query := `insert into user_
	(name,phone) 
	values ($1, $2) returning id, name, phone, created_at
	`
	rows, err := s.db.Query(
		query,
		"",
		user.Phone)

	//fmt.Println("CheckPoint 1")

	if err != nil {
		return nil, err
	}

	//fmt.Println("CheckPoint 2")

	users := []*types.User{}
	
	for rows.Next() {
		user, err := scan_Into_User(rows)
		if err != nil {
			return nil, err
		}
		users = append(users, user)
	}

	//fmt.Println("CheckPoint 3")

	return users[0], nil
}

func (s *PostgresStore) Get_Users() ([]*types.User, error) {
	rows, err := s.db.Query("select * from user_")

	if err != nil {
		return nil, err
	}

	users := []*types.User{}
	for rows.Next() {
		user, err := scan_Into_User(rows)
		if err != nil {
			return nil, err
		}
		users = append(users, user)
	}

	return users, nil
}

func(s *PostgresStore) Get_User_By_Phone(phone int) (*types.User, error) {
	
	rows, err := s.db.Query("select id, name, phone, created_at from user_ where phone = $1", phone)

	if err != nil {
		log.Fatal(err)
	}
	
	defer rows.Close()

	users := []*types.User{}

	for rows.Next() {
		user, err := scan_Into_User(rows)
		if err != nil {
			return nil, err
		}
		users = append(users, user)
	}

	if err := rows.Err(); err != nil {
		log.Fatal(err)
	}

	if len(users) == 0 {
		return nil, nil
	}
 
	return users[0], nil
}

func (s *PostgresStore) Update_User(hlc *types.Update_User) (*types.Update_User,error) {
	query := `update category
	set name = $1
	where id = $2 
	returning name, id`
	
	rows, err := s.db.Query(
		query, 
		hlc.Name,
		hlc.ID,
	)

	if err != nil {
		return nil, err
	}

	categories := []*types.Update_User{}
	
	for rows.Next() {
		category, err := scan_Into_Update_User(rows)
		if err != nil {
			return nil, err
		}
		categories = append(categories, category)
	}
	

	return categories[0], nil
}

func (s *PostgresStore) Delete_User(id int) error {
	_, err := s.db.Query("delete from category where id = $1", id)
	return err
}

func scan_Into_User(rows *sql.Rows) (*types.User, error) {
	user := new(types.User)
	err := rows.Scan(
		&user.ID,
		&user.Name,
		&user.Phone,
		&user.Created_At,
	)

	return user, err
}

func scan_Into_Update_User(rows *sql.Rows) (*types.Update_User, error) {
	category := new(types.Update_User)
	error := rows.Scan(
		&category.Name,
		&category.ID,
	)

	return category, error
} 

