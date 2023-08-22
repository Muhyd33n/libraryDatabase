SQL Server Management Studio (SSMS) Database EXAMPLE Project

A SQL Library Database project written in SSMS to show how to create a database and Normalization of Database

This project is an example of a library database that was built with a task details and instructions below -

Imagine you are employed as a database developer consultant for a library. They are currently 
in the process of developing a new database system which they require for storing 
information on their members, their library catalogue, loan history, and overdue fine 
repayments. 

Client Requirements
When a member joins the library, they need to provide their full name, address, date of birth 
and they must create a username and password to allow them to sign into the member portal. 
Optionally, they can also provide an email address and telephone number. Members are 
charged a fine if they have overdue books and the library has to keep track of the total 
overdue fines owed by an individual, how much they have repaid and the outstanding balance. 
When a member leaves, the library wants to retain their information on the system so they can 
continue marketing to them, but they should keep a record of the date the membership ended. 
Members can sign up and login online. 
When a member has overdue fines, they can repay some or all the overdue fines. Each 
repayment needs to be recorded, along with the date / time of the repayment, the amount 
repaid and the repayment method (cash or card).
The library has a catalogue of items. For each they have an item title, item type (which is 
classified as either a Book, Journal, DVD or Other Media), author, year of publication, date the 
item was added to the collection and current status (which is either On Loan, Overdue, 
Available or Lost/Removed). If the item is identified as being lost or removed from the 
collection, the library will record the date this was identified. If the item is a book, they will also 
record the ISBN.
The library wants to also keep a record of all current and past loans. Each loan should specify 
the member, the item, the date the item was taken out, the date the item is due back and the 
date the item was actually returned (this will be NULL if the item is still out). If the item is 
overdue, an overdue fee needs to be calculated at a rate of 10p per day.
The library processes hundreds of loans a day and details of the items on loan are business 
critical for them, so they need to avoid data loss if their systems go down. However, if their 
systems are down for a couple of hours, they think this isn’t too much of an issue for them.

