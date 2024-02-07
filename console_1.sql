-- SQL HomeWork #1


-- Part 1

/* Task #1
1.Use the Invoice table to determine the countries that have the lowest
invoices. Provide a table of BillingCountry and Invoices ordered by the
number of invoices for each country. The country with the most invoices
should appear last
*/

select billingcountry, count(1) as invoice
from invoice
group by billingcountry
order by invoice asc;

/*
Task #2
2. We would not like to throw a promotional Music Festival in the city we made
the least money. Write a query that returns the 5 city that has the lowest sum
of invoice totals. Return both the city name and the sum of all invoice totals.
*/
select billingcity, sum(total) revenue
from invoice
group by billingcity
order by revenue
limit 5;

/*
Task #3
3. The customer who has spent the least money will be declared the worst
customer. Build a query that returns the person who has spent the least
money. I found the solution by linking the following three: Invoice, InvoiceLine,
and Customer tables to retrieve this information, but you can probably do it
with fewer!
*/

with t as (select c.customerid, c.firstname, c.lastname, sum(i.total) AS Total
           from customer c
                    join invoice i on c.customerid = i.customerid
           group by c.customerid, c.firstname, c.lastname)
select (firstname || lastname) as StingyAssHole
from t
where t.Total = (select min(t.Total) from t);

/*
4.The team at Chinook would like to identify all the customers who listen to
Rock music. Write a query to return the email, first name, last name, and
Genre of all Rock Music listeners. Return your list ordered alphabetically by
email address starting with S.
*/

select c.email,c.firstname,c.lastname
from customer c join invoice i on c.customerid = i.customerid
    join invoiceline i2 on i.invoiceid = i2.invoiceid
    join track t on i2.trackid = t.trackid
    join genre g on t.genreid = g.genreid
where g.name = 'Rock'
    and c.email like 's%'
order by email asc;

/*
5.Write a query that determines the customer that has spent the most on
music for each country. Write a query that returns the country along with the
top customer and how much they spent. For countries where the top amount
spent is shared, provide all customers who spent this amount.
*/
with t as
         (select c.firstname, c.lastname, c.country,SUM(total) Expenditure
          from customer c
                   join invoice i on c.customerid = i.customerid
          group by firstname, lastname, c.country),
     t1 as
        (select t.country, max(t.Expenditure) as Expenditure
         from t
         group by t.country)
select DISTINCT firstname,lastname,t.country, t.Expenditure
from t, t1
where t.Expenditure = t1.Expenditure
order by Expenditure DESC



/*
Part 2
1. How many tracks appeared 5 times, 4 times, 3 times....?
*/
with t as
    (select count(i.trackid) quantity
     from invoiceline i
     group by i.trackid
     order by quantity DESC)
select quantity, count(quantity) as Occurence
from t
where quantity <= 5
group by quantity


/*
2. Which album generated the most revenue?
*/

with t as
(select a.title, SUM(i.total) as total
from customer c join invoice i on c.customerid = i.customerid
    join invoiceline i2 on i.invoiceid = i2.invoiceid
    join track t on i2.trackid = t.trackid
    join genre g on t.genreid = g.genreid
    join album a on t.albumid = a.albumid
group by a.title)
select *
from t
where total = (select max(total) from t);

/*
3. Which countries have the highest sales revenue? What percent of total
revenue does each country make up
*/
with t as
    (select c.country, sum(total) revenue
     from customer c join invoice i on c.customerid = i.customerid
     group by c.country
     order by revenue desc)
select t.country, t. revenue, ((round(t.revenue / t2.total * 100))::VARCHAR) || '%' as percentage
from t, (select SUM(total) as total from invoice) t2


/*
4. How many customers did each employee support, what is the average
revenue for each sale, and what is their total sale?
*/
SELECT
    e.EmployeeId,
    e.FirstName || ' ' || e.LastName AS EmployeeName,
    COUNT(c.CustomerId) AS NumberOfCustomers,
    AVG(i.Total) AS AverageRevenuePerSale,
    SUM(i.Total) AS TotalSale
FROM
    Employee e
LEFT JOIN
    Customer c ON e.EmployeeId = c.SupportRepId
LEFT JOIN
    Invoice i ON c.CustomerId = i.CustomerId
GROUP BY
    e.EmployeeId;

/*
5. Do longer or shorter length albums tend to generate more revenue?
*/
with average as
    (
        select avg(milliseconds) as average
        from track
    ),
    short as
    (select sum(total)
     from track t join invoiceline i on t.trackid = i.trackid
                  join invoice i2 on i.invoiceid = i2.invoiceid
     where t.milliseconds >= (select average from average)
     ),
    long as
        (
            select sum(total)
            from track t join invoiceline i on t.trackid = i.trackid
                        join invoice i2 on i.invoiceid = i2.invoiceid
            where t.milliseconds < (select average from average)
        )
select (select * from short) as short_revenue,
       (select * from long) as long_revenue

/*
6. Is the number of times a track appear in any playlist a good indicator of
sales?
a) Note: Calculate the sum of revenue based on appearance
*/
SELECT
    t.Name AS TrackName,
    COUNT(pt.PlaylistId) AS NumberOfPlaylists,
    SUM(i.Total) AS TotalRevenueFromTrack
FROM
    Track t
LEFT JOIN
    PlaylistTrack pt ON t.TrackId = pt.TrackId
LEFT JOIN
    InvoiceLine il ON t.TrackId = il.TrackId
LEFT JOIN
    Invoice i ON il.InvoiceId = i.InvoiceId
GROUP BY
    t.TrackId;



/*
7. How much revenue is generated each year, and what is its percent change
from the previous year?
*/

WITH YearlyRevenue AS (
    SELECT
        EXTRACT(YEAR FROM i.invoicedate) AS Year,
        SUM(i.Total) AS Revenue
    FROM
        invoice i
    GROUP BY
        EXTRACT(YEAR FROM i.InvoiceDate)
)
SELECT
    Year,
    Revenue,
    ROUND((Revenue - lag(Revenue) OVER (ORDER BY Year ASC)) * 100.0 / lag(Revenue) OVER (ORDER BY Year ASC), 2) AS PercentChangeFromPreviousYear
FROM
    YearlyRevenue;

