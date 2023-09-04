## SQL Server Management Studio (SSMS) Database EXAMPLE Project

A SQL Library Database project designed in SSMS to show how to create a database

This project is an example of a library database, this was built with task details and instructions below -

### Client Requirements

1. Create new members' full names, addresses, dob, username, and password to allow them to sign into the member portal. 
2. Optionally, members can also provide an email address and telephone number.
3. Members are charged a fine if they have overdue books and the library has to keep track of the total overdue fines owed by an individual, how much they have repaid, and the outstanding balance.
4. When a member leaves, the library retains their information for marketing, records of the membership end date should be kept. 
5. Members can sign up and log in online. 
6. When a member has overdue fines, they can repay some or all the overdue fines. Each repayment needs to be recorded, along with the date/time of the repayment, the amount 
  repaid, and the repayment method (cash or card).
7. The library has a catalogue of items. For each, they have an item title, item type (which is classified as either a Book, Journal, DVD or Other Media), author, year of publication, date the item was added to the collection, and current status (which is either On Loan, Overdue, Available or Lost/Removed). If the item is identified as being lost or removed from the collection, the library will record the date this was identified. If the item is a book, they will also record the ISBN.
8. The library wants to also keep a record of all current and past loans. Each loan should specify the member, the item, the date the item was taken out, the date the item is due back, and the date the item was actually returned (this will be NULL if the item is still out). If the item is overdue, an overdue fee needs to be calculated at a rate of 10p per day.

### Task Details

Design the database system based on the information provided above, along with a number of associated database objects, such as stored procedures, user-defined functions, views, and triggers. You should design and normalize your proposed database into 3NF, You should also consider using constraints when creating your database to help ensure data integrity. 

#### Entity relationship diagram
Below is the entity relationship diagram for the Database I created -
![Entity Relationship diagram](https://github.com/Muhyd33n/libraryDatabase/assets/55355325/18d199b7-f72a-4607-9d91-e3454c32a067)






