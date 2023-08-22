/*The Command below is used to create a database, which is named 'LibraryDatabase;'*/

CREATE DATABASE LibraryDatabase;


---The USE command is used to select the 'LibraryDatabase' from the list of Available Databases
USE  LibraryDatabase;


/*I have created a seperate table to record the member address,. The AddressID will be a column in the member table that will reference 
their individual addresses.
The UNIQUE constraint combine Address1 and Address2, this two columns should UNIQUEly determine 
the member address, since the data that will be inserted will be UK Addresses.*/

CREATE TABLE Addresses (
MemberAddressID int IDENTITY(501,1) NOT NULL PRIMARY KEY,
MemberAddress1 nvarchar(50) NOT NULL,
MemberAddress2 nvarchar(50) NULL,
City nvarchar(50) NULL,
Postcode nvarchar(10) NOT NULL,
CONSTRAINT UC_Address UNIQUE (MemberAddress1, Postcode));


/*This table holds specific information of each of the Library Members. The Address of each of the Members is  in
a  seperate table. The Id of the Addresses table will be referenced in the Members table. To ensure data integrity, Unique Constraint
is used to ensure no member use an already existed username, and email. Also, CHECK constraint is used to ensure the 
email provided by Members will adhere to the fundamental form of email addresses.  NOTE: Instead of storing Members Password 
inside  the database, i want to store the salted hash of the password to defend against serious security risk*/
CREATE TABLE Members (
MemberID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
MemberFirstName nvarchar(50) NOT NULL,
MemberMiddleName nvarchar(50)  NULL,
MemberLastName nvarchar(50) NOT NULL,
MemberAddressID int NOT NULL,     ---this column will reference the Addresses table in members table
MemberDOB date NOT NULL,
MemberUsername nvarchar(30) UNIQUE NOT NULL,
PasswordHash BINARY(64) NOT NULL, Salt UNIQUEIDENTIFIER,
MemberEmail nvarchar(100) NULL CHECK (MemberEmail LIKE '%_@_%._%'),  ---It;s null because the email of members is an Optional requirement for registration, same with MemberTelephone
MemberTelephone nvarchar(20)  NULL,
MembershipStatus nvarchar(10) NOT NULL CHECK (MembershipStatus IN ('Active', 'Inactive')),    ---This column is included to record the current status of members, Inactive members will be marketed to.
CONSTRAINT FK_MemberAddress FOREIGN KEY (MemberAddressID)
 REFERENCES Addresses(MemberAddressID));

 /*It has been assummed that there are 3  different categories of subscription, namely Student, Standard and Premium. Benefits members enjoy may differs from one subscription
 category to the other. For example, the Premium categories might have access to free WIFI, and access to exclusie members room*/

CREATE TABLE SubscriptionCategory(
SubscriptionCategoryID  Int IDENTITY(1,1) NOT NULL PRIMARY KEY,
SubscriptionCategory nvarchar(30) NOT NULL,
CategoryFeePerMonth money NOT NULL);

/*Another table has been created to record the  duration of subscription, amount paid, also the date the membership will end */

CREATE TABLE MemberSubscription(
SubscriptionID Int IDENTITY(1,1) NOT NULL PRIMARY KEY,
MemberID int NOT NULL FOREIGN KEY(MemberID) REFERENCES Members(MemberID),
SubscriptionCategoryID int NOT NULL FOREIGN KEY(SubscriptionCategoryID) 
REFERENCES SubscriptionCategory(SubscriptionCategoryID),
SubscriptionPaid Money NOT NULL,
NumberofMonthSubscribed int NOT NULL,
MembershipStartDate date NOT NULL,
MembershipEndDate date NOT NULL);


/*This table holds the item information which includes the Title, ItemType,  the author, Year of Publication and the ISBN 
of Book Items. Check Constraint is used to ensure data integrity.
 */

CREATE TABLE LibraryCatalogue(
ItemID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
ItemTitle nvarchar(50) NOT NULL,
ItemType  nvarchar(20) NOT NULL CHECK (ItemType IN ('Book', 'Journal', 'DVD', 'Other Media')),  --Different item types, as provided by the brief
Author nvarchar(30) NOT NULL,
YearOfPublication date NOT NULL,
BookISBN nvarchar(30) NULL);



/*It is assumed that a library will have more than one copy for some of the items in their Catalogue, hence there is need for ItemCopies table . The ItemID
will reference the LibraryCatalogue table in the child's table(ItemCopies). */
CREATE TABLE ItemCopies(
ItemCopyID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
ItemID int NOT NULL,
ItemAddedDate date NOT NULL,
ItemCurrentStatus nvarchar(30) NOT NULL 
CHECK (ItemCurrentStatus IN ('Loan', 'Overdue', 'Available', 'LostOrRemoved')),    --The is list of status provided in the brief
LostOrRemovedDate date NULL,
CONSTRAINT FK_ItemCopies FOREIGN KEY (ItemID)  REFERENCES LibraryCatalogue(ItemID));




/*The MemberID column references the parent's(Members) table in this child's(LoanHistory) table. The itemcopyid column
references the parent's(Library Catalogue) table in this child's( LoanHistory) table. Also,   ItemReturnedDate can be NULL
if the item is still Out*/
CREATE TABLE LoanHistory(
LoanID  int IDENTITY(1,1) NOT NULL PRIMARY KEY,
MemberID  int  NOT NULL,      
ItemCopyID  int  NOT NULL,	
ItemTakenOutDate date NOT NULL,
ItemDueDate date NOT NULL, 
ItemReturnedDate date NULL,
FineAmount MONEY NULL,
CONSTRAINT FK_MemberLoan FOREIGN KEY (MemberID)  REFERENCES Members (MemberID),
CONSTRAINT FK_LoanItem FOREIGN KEY (ItemCopyID)  REFERENCES ItemCopies(ItemCopyID));   


/*Check Constraint is used on RepaymentMethod column to ensure data integrity. The column will allow only Cash or Card as payment
method. */

CREATE TABLE FineRepayment (
FineRepaymentID  int IDENTITY(1,1) NOT NULL PRIMARY KEY,
LoanID  int  NOT NULL,
MemberID int NOT NULL , 
AmountPaid money NOT NULL,
PaymentDate datetime NOT NULL,
PaymentMethod nvarchar(20) NOT NULL CHECK (PaymentMethod IN ('Cash',   'Card')),
CONSTRAINT FK_LoanFineRepayment FOREIGN KEY (LoanID)  REFERENCES LoanHistory(LoanID),
CONSTRAINT FK_MemberFineRepayment FOREIGN KEY (MemberID)  REFERENCES Members (MemberID)); 







/*2. The library also requires stored procedures or user-defined functions to do the following things:
a) Search the catalogue for matching character strings by title. Results should be sorted with most
recent publication date first. This will allow them to query the catalogue looking for a specific item.*/

/*The statement below create a store procedure that search the catalogue for matching character strings by titles.*/
 
 GO;
 
 CREATE PROCEDURE spSearchCatalogue
  @titleString nvarchar(30)
AS
 BEGIN
 BEGIN TRY
 BEGIN TRANSACTION;
 SELECT *             
 FROM LibraryCatalogue
 WHERE ItemTitle LIKE '%' + @titleString + '%'    --Wildcard operation is used together with the condition statememt to filter the retrieved records to include where the item title has the @titlestring anywhere in the title
 ORDER BY YearOfPublication DESC;
 COMMIT TRANSACTION;
END TRY
BEGIN CATCH
ROLLBACK TRANSACTION;
  --Handle the error here
 PRINT ERROR_MESSAGE();
 END CATCH;
 END;

---The above Stored procedure can be executed with the below line of code
EXEC spSearchCatalogue @titleString = 'The' 



/*Question 2b: Return a full list of all items currently on loan which have a due date of less than five days from
    the current date (i.e., the system date when the query is run)*/

/* DATEADD(interval, number, date) function add number to or substract number from an interval, then return the date.   */

 GO;
 
CREATE PROCEDURE spLoanDueDateLessThanFive
AS
BEGIN
BEGIN TRY
  BEGIN TRANSACTION;
  SELECT *
  FROM LoanHistory
  WHERE ItemReturnedDate IS NULL   ---ItemReturnedDate is NULL When the item is not returned 
    AND DATEDIFF(day, GETDATE(), ItemDueDate) < 5
    AND DATEDIFF(day, GETDATE(), ItemDueDate) >= 0
  COMMIT TRANSACTION;
END TRY
BEGIN CATCH
  ROLLBACK TRANSACTION;
  --Handle the error here
  PRINT ERROR_MESSAGE();
END CATCH;
END;

--Run the code below
EXEC spLoanDueDateLessThanFive;


/*Question 2c: 

Insert a new member into the database*/

 --- NOTE: ACCESS CONTROL ON THIS TRIGGER IS GIVEN TO THE LIBRARIAN, CHECK CELL 752 for details
 GO; 


CREATE PROCEDURE spAddMember                                                            
  @firstname nvarchar(50),
  @middlename nvarchar(50),
  @lastname nvarchar(50), 
  @addressid int, 
  @dateofbirth date,
  @username nvarchar(30),
  @password nvarchar(50),
  @email nvarchar(100),
  @telephone nvarchar(20),
  @membershipstatus nvarchar(20)
AS
BEGIN TRANSACTION
BEGIN TRY
DECLARE @salt UNIQUEIDENTIFIER=NEWID()
--Insert member record
  INSERT INTO Members (MemberFirstName, MemberMiddleName, MemberLastName, MemberAddressID, MemberDOB, 
  MemberUsername, PasswordHash, Salt, MemberEmail, MemberTelephone, MembershipStatus)
VALUES (@firstname, @middlename, @lastname, @addressid, @dateofbirth, @username, HASHBYTES('SHA2_512',
@password+CAST(@salt AS NVARCHAR(36))), @salt, @email, @telephone,  @membershipstatus)
COMMIT TRANSACTION
END TRY
BEGIN CATCH
--Looks like there was an error!
IF @@TRANCOUNT > 0
	ROLLBACK TRANSACTION
	DECLARE @ErrMsg nvarchar(4000), @ErrSeverity int
	SELECT @ErrMsg = ERROR_MESSAGE(), @ErrSeverity =
	ERROR_SEVERITY()
	RAISERROR(@ErrMsg, @ErrSeverity, 1)
END CATCH;

  ---To test the Stored Procedure created for adding new member,  run the code below

 EXEC spAddMember @firstname = 'Mark', @middlename = NULL, @lastname = 'Hughes', @addressid = 513, @dateofbirth = '1998-12-31', @username = 'marknn01', 
 @password = 'password1741', @email = NULL, @telephone = '01122339155', @membershipstatus = 'Active'




/*Question 2d 

Update the details for an existing member*/

CREATE PROCEDURE spUpdateMember 
 @memberid int, 
 @firstname nvarchar(50),
 @middlename nvarchar(50),
 @lastname nvarchar(50), 
  @addressid int,
  @dateofbirth date,
  @username nvarchar(30),
  @password nvarchar (50),
  @email nvarchar(100),
  @telephone nvarchar(20),
 @membershipstatus nvarchar(20)
  AS
BEGIN TRANSACTION
BEGIN TRY
DECLARE @salt UNIQUEIDENTIFIER=NEWID()
--Update member record
  UPDATE Members
 SET MemberFirstName = @firstname, MemberMiddleName =@middlename , MemberLastName = @lastname, 
 MemberAddressID =@addressid , MemberDOB =@dateofbirth, MemberUsername = @username, PasswordHash = HASHBYTES('SHA2_512',
@password+CAST(@salt AS NVARCHAR(36))), MemberEmail = @email, MemberTelephone= @telephone, MembershipStatus = @membershipstatus
  WHERE MemberID = @memberid
COMMIT TRANSACTION
END TRY
BEGIN CATCH
--Looks like there was an error!
IF @@TRANCOUNT > 0
	ROLLBACK TRANSACTION
	DECLARE @ErrMsg nvarchar(4000), @ErrSeverity int
	SELECT @ErrMsg = ERROR_MESSAGE(), @ErrSeverity =
	ERROR_SEVERITY()
	RAISERROR(@ErrMsg, @ErrSeverity, 1)
END CATCH;
 
 /*In the below Execution code 'EXEC  spUpdateMember ' , the code will update the members details with whatever change you provided for the columns. 
 Note that unlike the spAddMember, here the @memberid has to be provided. the memberemail of  the Member was NULL. i will run the store procedure to update the
 members email to 'anderson12@gmail.com'    */
 EXEC spUpdateMember  @memberid = 16,
 @firstname = 'Anderson', @middlename = NULL, @lastname = 'Mo', @addressid = 515, @dateofbirth = '1997-12-31', @username = 'anderson', 
 @password = 'password141', @email = 'anderson12@gmail.com' , @telephone = '01122334455', @membershipstatus = 'Active'


/*QUESTION 3 

The library wants be able to view the loan history, showing all previous and current loans, and including details of the item borrowed,
borrowed date, due date and any associated fines for each loan. You should create a view containing all the required information. */
GO;

CREATE VIEW LoanHistoryView 
AS
SELECT c.ItemCopyID, l.LoanID, l.MemberID, i.ItemTitle, i.ItemType, i.Author, i.YearOfPublication,
i.BookISBN,l.ItemTakenOutDate, l.ItemDueDate,
IIF(GETDATE()  > l.ItemDueDate, (DATEDIFF(day, l.ItemDueDate, GETDATE()) * 0.10), 0) AS AssociatedFine
FROM LibraryCatalogue AS i
JOIN ItemCopies AS c ON i.ItemID = c.ItemID
JOIN LoanHistory AS l ON l.ItemCopyID = c.ItemCopyID;

---Query the LoanHistoryView
SELECT * FROM LoanHistoryView



/* QUESTION 4 :
Create triggers so that the current status of an item automatically updates to Overdue if the item has not
been returned by the due date, and so that the current status updates to Available when the book is returned.*/
  GO;
  
  CREATE TRIGGER trgUpdateItemStatus         
ON LoanHistory
AFTER INSERT, UPDATE
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Update item status to Available when the book is returned
        IF UPDATE(ItemReturnedDate)
        BEGIN
            UPDATE ItemCopies
            SET ItemCurrentStatus = 'Available'
            FROM inserted i
            INNER JOIN LoanHistory l ON i.LoanID = l.LoanID
            INNER JOIN ItemCopies c ON l.ItemCopyID = c.ItemCopyID
            WHERE l.ItemReturnedDate IS NOT NULL
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        --Handle the error here
        PRINT ERROR_MESSAGE();
    END CATCH;
END;




/* QUESTION 5:
You should provide a function, view, or SELECT query which allows the library to identify the total number of loans 
made on a specified date.*/

---Function that allows the library to identify the total number of loans made on a specified date
GO
 
CREATE FUNCTION NumOfLoansOnDate (@loanDate DATE)
RETURNS INT
AS
BEGIN
    DECLARE @numOfLoans INT;

    SELECT @numOfLoans = COUNT(*) 
    FROM LoanHistory
    -- loan date that matches the parameter passed
    WHERE CONVERT(DATE, ItemTakenOutDate) = @loanDate; 
    RETURN @numOfLoans; -- returns the count
END

GO

/*the select query below retrieves  the total number of loans made on 21st of March, 2023, using the above dbo.NumOfLoansOnDate  FUNCTION */

SELECT dbo.NumOfLoansOnDate('2023-03-21') AS NumOfLoans;





/*QUESTION 6
So that you can demonstrate the database to the client you should insert some records into each of the tables
(you only need to add a small number of rows to each, however, you should also ensure the data you input allows 
you to adequately test that all SELECT queries, user-defined functions, stored procedures, and triggers are working*/


---Insert records into the addresses table

 INSERT INTO Addresses (MemberAddress1, MemberAddress2, City, Postcode )
 VALUES ('22 Market Street', 'Flat 3', 'Manchester', 'M1 1PW'),
                ('12 Oxford Road', NULL, 'Salford', 'M5 4WT'),
                ('44 High Street', 'Suite 6B', 'Bolton', 'BL1 1EY'),
                ('9 Park Lane', NULL, 'Oldham', 'OL1 1SS'),
                ('67 Station Road', 'Flat 5C', 'Stockport', 'SK1 1JX'),
                ( '89 Oxford Street', NULL, 'Rochdale', 'OL16 1PG'),
                ('55 Church Lane', 'Apartment 2D', 'Wigan', 'WN1 1AB'),
                ('12 Victoria Road', 'Unit 2', 'Bury', 'BL9 0EB'),
                ('9 Market Square', NULL, 'Altrincham', 'WA14 1PF'),
               ( '35 Highgate Hill', 'Flat 4', 'Ashton-under-Lyne', 'OL6 6AX'),
			   ('13 Park Lane', 'Flat 1C', 'Bury', 'BL9 0QS'),
               ('62 Oxford Street', NULL, 'Manchester', 'M1 5EJ'),
               ('42 Market Street', 'Suite 7B', 'Rochdale', 'OL16 1JG'),
               ('10 Park Avenue', NULL, 'Salford', 'M6 7PT'),
               ('77 Church Lane', 'Flat 3D', 'Oldham', 'OL2 8PA');


-- Execute this  Select Statement to retrieve all records in the table 
   SELECT * FROM Addresses;
              

/*Now lets insert some random records into the the members table. the store procedure earlier created is used to populate the said table.
Note the details of 15 members below were randomly created.This is not a real world details of anyone.*/

EXEC spAddMember @firstname = 'Anna', @middlename = NULL, @lastname = 'Johnson', @addressid = 501, @dateofbirth = '1985-05-10', @username = 'annaj', 
@password = 'password1', @email = 'annaj@gmail.com', @telephone = NULL, @membershipstatus = 'Active'
EXEC spAddMember @firstname = 'David', @middlename = 'K', @lastname = 'Chen', @addressid = 502, @dateofbirth = '1992-08-20', @username = 'davidkc', 
@password = 'password2', @email = 'davidkc@gmail.com', @telephone = '09876543210', @membershipstatus = 'Active'
EXEC spAddMember @firstname = 'Emily', @middlename = NULL, @lastname = 'Lee', @addressid = 503, @dateofbirth = '1988-03-15', @username = 'emilylee', 
@password = 'password3', @email = 'emilylee@gmail.com', @telephone = '07865432109', @membershipstatus = 'Active'
EXEC spAddMember @firstname = 'Jason', @middlename = 'M', @lastname = 'Nguyen', @addressid = 504, @dateofbirth = '1995-11-22', @username = 'jasonmnguyen', 
@password = 'password4', @email = 'jasonmnguyen@gmail.com', @telephone = '01122334455', @membershipstatus = 'Active'
EXEC spAddMember @firstname = 'Karen', @middlename = NULL, @lastname = 'Kim', @addressid = 505, @dateofbirth = '1987-07-01', @username = 'karenkim', 
@password = 'password5', @email = 'karenkim@gmail.com', @telephone = NULL, @membershipstatus = 'Active'
EXEC spAddMember @firstname = 'Mark', @middlename = 'R', @lastname = 'Garcia', @addressid = 506, @dateofbirth = '1993-02-18', @username = 'markrgarcia', 
@password = 'password6', @email = 'markrgarcia@gmail.com', @telephone = '03344556677', @membershipstatus = 'Active'
EXEC spAddMember @firstname = 'Nancy', @middlename = NULL, @lastname = 'Brown', @addressid = 507, @dateofbirth = '1986-09-30', @username = 'nancybrown', 
@password = 'password7', @email = 'nancybrown@gmail.com', @telephone = '01122334455', @membershipstatus = 'Active'
EXEC spAddMember @firstname = 'Oliver', @middlename = 'L', @lastname = 'Ng', @addressid = 508, @dateofbirth = '1990-06-05', @username = 'oliverng', 
@password = 'password8', @email = 'oliverng@gmail.com', @telephone = '07766554433', @membershipstatus = 'Active'
EXEC spAddMember @firstname = 'Paul', @middlename = NULL, @lastname = 'Wong', @addressid = 509, @dateofbirth = '1984-12-25', @username =  'paulwng', 
@password = 'password9', @email = 'paulwong@gmail.com', @telephone = '0767584433', @membershipstatus = 'Active'
EXEC spAddMember @firstname = 'Rachel', @middlename = 'A', @lastname = 'Liu', @addressid = 510, @dateofbirth = '1996-04-14', @username = 'rachelliu', 
@password = 'password9', @email = 'rachelliu@gmail.com', @telephone = '07456983210', @membershipstatus = 'Active'
EXEC spAddMember @firstname = 'Samuel', @middlename = NULL, @lastname = 'Kang', @addressid = 511, @dateofbirth = '1989-11-01', @username = 'samuelkang', 
@password = 'password10', @email = 'samuelkang@gmail.com', @telephone = '03344556677', @membershipstatus = 'Active'
EXEC spAddMember @firstname = 'Tina', @middlename = 'L', @lastname = 'Hu', @addressid = 512, @dateofbirth = '1991-02-28', @username = 'tinahu', 
@password = 'password11', @email = 'tinahu@gmail.com', @telephone = NULL, @membershipstatus = 'Active'
EXEC spAddMember @firstname = 'Victor', @middlename = NULL, @lastname = 'Chu', @addressid = 513, @dateofbirth = '1987-06-12', @username = 'victorchu', 
@password = 'password12', @email = 'victorchu@gmail.com', @telephone = '09876543210', @membershipstatus = 'Active'
EXEC spAddMember @firstname = 'Wendy', @middlename = 'J', @lastname = 'Zhang', @addressid = 514, @dateofbirth = '1994-09-23', @username = 'wendyzhang', 
@password = 'password13', @email = 'wendyzhang@gmail.com', @telephone = '07788990011', @membershipstatus = 'Active'
EXEC spAddMember @firstname = 'Xavier', @middlename = NULL, @lastname = 'Wu', @addressid = 515, @dateofbirth = '1998-12-31', @username = 'xavierwu', 
@password = 'password14', @email = NULL, @telephone = '+44 1122334455', @membershipstatus = 'Active'

---Run this query to see the result of the above execution code
   SELECT * FROM [dbo].[Members]
  

--Using the Insert Statement, Let's insert into the subscription Category table( the categories are in Student, Standard, Premium)
 INSERT INTO  SubscriptionCategory(SubscriptionCategory, CategoryFeePerMonth)
 VALUES('Student', 10), 
				('Standard', 15), 
				('Premium', 20);

---Run this query to see the result of the above insert statement
   SELECT * FROM SubscriptionCategory;

   ---Insert Records in MemberSubscription Table.

 INSERT INTO MemberSubscription (MemberID, SubscriptionCategoryID, SubscriptionPaid, NumberofMonthSubscribed, MembershipStartDate, MembershipEndDate)
VALUES (13, 1, 30.00, 3, '2023-02-01', '2023-04-30'),
(2, 2, 90.00, 6, '2023-02-15', '2023-08-14'),
(3, 1, 120.00, 12, '2022-03-05', '2023-03-04'),
(4, 2, 45.00, 3, '2023-04-10', '2023-07-09'),
(5, 2, 75.00, 5, '2023-05-15', '2023-10-14'),
(6, 3, 240.00, 12, '2022-06-01', '2023-05-31'),
(7, 1, 20.00, 2, '2023-02-15', '2023-04-14'),
(8, 1, 60.00, 6, '2022-08-10', '2023-02-09'),
(10, 2, 30.00, 2, '2023-04-01', '2023-05-30'),
(9, 2, 105.00, 7, '2022-09-15', '2023-04-14'),
(11, 3, 240.00, 12, '2022-11-01', '2023-10-31'),
(12, 1, 50.00, 5, '2022-12-05', '2023-05-04'),
(15, 3, 100.00, 5, '2023-01-01', '2023-05-31'),
(14, 1, 90.00, 9, '2023-02-10', '2023-11-09'),
(1, 2, 90.00, 6, '2023-03-01', '2023-08-31');

---Query the MemberSubscription table

SELECT * FROM MemberSubscription;

/*Let us insert 30 items into the Library Catalogue, ISBN are recorded for only book item, as required by the brief*/

INSERT INTO LibraryCatalogue (ItemTitle, ItemType, Author, YearOfPublication, BookISBN)
VALUES
('The Sopranos - The Complete Series', 'DVD', 'David Chase', '1999-01-10', NULL),
('The Great Gatsby', 'Book', 'F. Scott Fitzgerald', '1925-04-10', '978-0743273565'),
('To Kill a Mockingbird', 'Book', 'Harper Lee', '1960-07-11', '978-0061120084'),
('1984', 'Book', 'George Orwell', '1949-06-08', '978-0451524935'),
('The Godfather', 'DVD', 'Francis Ford Coppola', '1972-03-24', NULL),
('Jurassic Park', 'DVD', 'Steven Spielberg', '1993-06-11', NULL ),
('The Office - Season One', 'DVD', 'Greg Daniels', '2005-03-22', NULL),
('Animal Farm', 'Book', 'George Orwell', '1945-08-17', '978-0451526342'),
('Pride and Prejudice', 'Book', 'Jane Austen', '1813-01-28', '978-0141439518'),
('The Catcher in the Rye', 'Book', 'J.D. Salinger', '1951-07-16', '978-0316769488'),
('Brave New World', 'Book', 'Aldous Huxley', '1932-06-01', '978-0060850524'),
('Gone Girl', 'Book', 'Gillian Flynn', '2012-06-05', '978-0307588371'),
('The Martian', 'Book', 'Andy Weir', '2011-09-27', '978-0553418026'),
('Jurassic Park', 'Book', 'Michael Crichton', '1990-11-20', '978-0345370778'),
('The Shining', 'Book', 'Stephen King', '1977-01-28', '978-0307743657'),
('The Silence of the Lambs', 'Book', 'Thomas Harris', '1988-05-20', '978-0312924584'),
('National Geographic Magazine - January 2023', 'Journal', 'National Geographic Society', '2023-01-01', NULL),
('The New York Times - November 4, 2020', 'Journal', 'The New York Times', '2020-11-04', NULL),
('Scientific American - January 2022', 'Journal', 'Scientific American', '2022-01-01', NULL),
('Rolling Stone Magazine - September 2021', 'Journal', 'Rolling Stone', '2021-09-01', NULL),
('Forbes Magazine - April 2022', 'Journal', 'Forbes', '2022-04-01', NULL),
('Breaking Bad - The Complete Series', 'DVD', 'Vince Gilligan', '2008-01-20', NULL),
('Lord of the Flies', 'Book', 'William Golding', '1954-09-17', '978-0399501487'),
('The Hobbit', 'Book', 'J.R.R. Tolkien', '1937-09-21', '978-0547928227'),
('Harry Potter and the Philosophers Stone', 'Book', 'J.K. Rowling', '1997-06-26', '978-0747532743'),
('The Hunger Games', 'Book', 'Suzanne Collins', '2008-09-14', '978-0439023481'),
('The Diary of a Young Girl', 'Book', 'Anne Frank', '1947-06-25', '978-0141315188'),
('The Hitchhikers Guide to the Galaxy', 'Book', 'Douglas Adams', '1979-10-12', '978-0345391803'),
('The Da Vinci Code', 'Book', 'Dan Brown', '2003-03-18', '978-0307474278'),
('The Girl with the Dragon Tattoo', 'Book', 'Stieg Larsson', '2005-08-23', '978-0307949486');

---Query the Library Catalogue table 

 

---Insert into the ItemCopies Table, In realities every library has more than one copy for most of their items. Here my item 1 has five copies.
INSERT INTO ItemCopies (ItemID, ItemAddedDate, ItemCurrentStatus, LostOrRemovedDate)
VALUES
-- Item 1 has 5 copies, 1 of it is on loan and 4 are available
(1, '2023-01-01', 'Available', NULL),
(1, '2023-01-01', 'Available', NULL),
(1, '2023-01-01', 'Available', NULL),
(1, '2023-01-01', 'Available', NULL),
(1, '2023-01-01', 'Loan', NULL),
(2, '2022-11-01', 'LostOrRemoved', '2023-04-01'),
(2, '2022-11-01', 'Available', NULL),
(2, '2022-11-01', 'Available', NULL),
(3, '2022-03-01', 'Available', NULL),
(4, '2022-05-01', 'Available', NULL),
(4, '2022-06-01', 'Available', NULL),
(5, '2022-07-01', 'Loan', NULL),
(6, '2022-09-01', 'Available', NULL),
(6, '2022-10-01', 'Available', NULL),
(7, '2022-11-01', 'Loan', NULL),
(8, '2023-01-01', 'Available', NULL),
(9, '2022-03-01', 'Loan', NULL),
(10, '2022-05-01', 'Available', NULL),
(10, '2022-06-01', 'LostOrRemoved', '2023-03-18'),
(11, '2022-07-01', 'Loan', NULL),
(12, '2022-09-01', 'Available', NULL),
(12, '2022-10-01', 'LostOrRemoved', '2023-01-15'),
(13, '2022-11-01', 'Loan', NULL),
(14, '2023-01-01', 'Available', NULL),
(14, '2023-02-01', 'LostOrRemoved', '2023-02-15'),
(15, '2022-03-01', 'Loan', NULL),
(15, '2022-04-01', 'Available', NULL),
(16, '2022-05-01', 'Available', NULL),
(16, '2022-06-01', 'LostOrRemoved', '2022-06-25'),
(17, '2022-07-01', 'Loan', NULL),
(18, '2022-09-01', 'Available', NULL),
(18, '2022-10-01', 'LostOrRemoved', '2022-10-15'),
(19, '2022-12-01', 'Loan', NULL),
(20, '2023-01-01', 'Available', NULL),
(20, '2023-01-01', 'LostOrRemoved', '2023-02-28'),
(21, '2022-03-01', 'Loan', NULL),
(22, '2022-05-01', 'Available', NULL),
(23, '2022-08-01', 'Loan', NULL),
(24, '2022-09-01', 'Available', NULL),
(25, '2022-12-01', 'Loan', NULL),
(26, '2023-01-01', 'Available', NULL),
(26, '2023-02-01', 'LostOrRemoved', '2023-03-15'),
(27, '2022-04-01', 'Available', NULL),
(28, '2022-05-01', 'Available', NULL),
(29, '2022-07-01', 'Available', NULL),
(29, '2022-08-01', 'Available', NULL),
(30, '2022-09-01', 'Available', NULL),
(30, '2022-10-01', 'LostOrRemoved', '2022-12-15');

--To retrieve the records in item copies

SELECT * FROM  ItemCopies;
   

---Insert Into LoanHistory table 
 INSERT INTO LoanHistory( MemberID, ItemCopyID, ItemTakenOutDate, ItemDueDate, ItemReturnedDate, FineAmount )

 VALUES  (2, 5, '2023-03-21',  '2023-04-20', NULL, NULL ),
(2, 12, '2023-03-21',  '2023-04-20', NULL, NULL),
(5, 15, '2023-04-12',  '2023-04-26', NULL, NULL),
(8, 17, '2023-04-11',  '2023-05-10', NULL, NULL),
(5, 20, '2023-04-10',  '2023-05-09', NULL, NULL),
(3, 23, '2023-04-14',  '2023-05-13', NULL, NULL),
(15, 26, '2023-04-13',  '2023-05-12', NULL, NULL),
(4, 30, '2023-04-01',  '2023-04-30', NULL, NULL),
(2, 33, '2023-04-14',  '2023-05-13', NULL, NULL),
(2, 36, '2023-02-14',  '2023-04-13', '2023-04-13', NULL),
(14, 38, '2023-01-14',  '2023-03-13',  '2023-03-28', NULL),
(15, 40, '2023-01-14',  '2023-03-18',  '2023-03-28', NULL);


 ---To retrieve all records in the Loan History Table
   SELECT * FROM LoanHistory;

 
 
 
 --Insert records in FineRepayment table

 INSERT INTO FineRepayment (LoanID, MemberID, AmountPaid, PaymentDate, PaymentMethod)
 VALUES (11, 14, 0.90, '2023-04-15', 'Cash'), 
 (11, 14, 0.15, '2023-04-20', 'Card')

 ---To retrieve all records in the FineRepayment Table

    SELECT * FROM   FineRepayment;


/* Question 7*/


/* This trigger update the membership status column of members table. the trigger  change it to 'inactive' from 'active'  when their subscription expires.
The  Library will continue to market to this customers with inactive status.*The trigger uses a join between the Members table, the inserted table (which
contains the new values after the update), and the deleted table (which contains the old values before the update) to identify the relevant member(s). */


---Stored Procedure to Update the MembershipStatus 

GO;

CREATE TRIGGER UpdateMembershipStatus
ON MemberSubscription
AFTER INSERT, UPDATE
AS
BEGIN
 BEGIN TRY
 BEGIN TRANSACTION;
        UPDATE Members
        SET MembershipStatus = 'Inactive'
        FROM Members
        INNER JOIN inserted ON Members.MemberID = inserted.MemberID
        WHERE GETDATE() > inserted.MembershipEndDate
COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        --Handle the error here
		PRINT ERROR_MESSAGE();
    END CATCH;
END;




/*This procedure is meant to be ran everyday to calculate the Fine amount of Members and also update the Fine amount when repayment of loans fines are made. */

GO;

CREATE PROCEDURE FineAmountCalculation
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        -- Calculate the fine amount
        UPDATE LoanHistory
        SET FineAmount = 
            CASE 
                WHEN ItemDueDate > GETDATE() THEN 0
                ELSE DATEDIFF(DAY, ItemDueDate, ISNULL(ItemReturnedDate, GETDATE()) ) * 0.10
            END
        WHERE GETDATE() > ItemDueDate

        -- Reduce the fine amount based on repayments
        UPDATE lh
        SET lh.FineAmount = lh.FineAmount - ISNULL(fr.TotalAmountPaid, 0)
        FROM LoanHistory AS lh
        JOIN (
            SELECT LoanID, MemberID, SUM(AmountPaid) AS TotalAmountPaid
            FROM FineRepayment AS fr
            GROUP BY LoanID, MemberID  ) fr 
      ON lh.LoanID = fr.LoanID AND lh.MemberID = fr.MemberID
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        --Handle the error here
        PRINT ERROR_MESSAGE();
    END CATCH;
END;

---This is the execution code for the above procedure
 EXEC FineAmountCalculation

 

 --This is a view that retrieve the total fine repayments of members. 
 GO;

 CREATE VIEW MemberFineRepayments AS
SELECT m.MemberFirstName, m.MemberLastName, 
       (SELECT SUM(AmountPaid) 
        FROM FineRepayment 
        WHERE MemberID = m.MemberID) AS TotalFineRepayments
FROM Members m;



  --Select Statement to retrieve the records in the MemberFineRepayments View
   SELECT * FROM MemberFineRepayments;



/*This function below joins the Members table with the MemberSubscription table to get the membership  subsciption details of each member*/

GO; 

CREATE FUNCTION GetMemberSubscriptions (@MemberID int)
RETURNS TABLE
AS
RETURN 
    SELECT m.MemberID, m.MemberFirstName, m.MemberLastName, 
           c.SubscriptionCategory, s.SubscriptionPaid, s.NumberofMonthSubscribed,
           s.MembershipStartDate, s.MembershipEndDate
    FROM Members AS m
    INNER JOIN MemberSubscription AS s ON m.MemberID = s.MemberID
    INNER JOIN SubscriptionCategory AS c ON c.SubscriptionCategoryID = s.SubscriptionCategoryID
    WHERE m.MemberID = @MemberID;

	--Test the function with the member ID  1

  SELECT * FROM dbo.GetMemberSubscriptions(1);



 ---  TRIGGER THAT UPDATE THE ITEM STATUS TO OVERDUE
  ---This trigger is created to update the item copy status to Overdue  if the item is not returned on due date 
  
  GO;

  CREATE TRIGGER trg_UpdateItemStatusOnLoanExpiration
ON LoanHistory
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;
		---the update statement 
        UPDATE ItemCopies
        SET ItemCurrentStatus = 'Overdue'        
        FROM ItemCopies
        JOIN inserted i ON ItemCopies.ItemCopyID = i.ItemCopyID
        WHERE GETDATE() > i.ItemDueDate      ----Condition for the trigger 
          AND ItemCopies.ItemCurrentStatus = 'Loan';

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0  ---condition to check if a transaction is active before attempting to roll it back
            ROLLBACK TRANSACTION;
---Handles the error here 
        DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE(),
                @ErrorSeverity INT = ERROR_SEVERITY(),
                @ErrorState INT = ERROR_STATE();

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;


  -- Start Of Access Control  

  ------ Creating a log in for the Database   
  CREATE LOGIN Librarian WITH PASSWORD = 'Lib1234';    

    ---create a user
  CREATE USER librarian_user FOR LOGIN Librarian;


   ---Give access control on  spAddMember to the librarian 

  GRANT EXEC ON spAddMember TO librarian_user;


    ---End of Access Control


 


















































