--Q: Who is the senior most employee based on the job title?
select * from employee
order by levels desc	
limit 1

-- Q: Which country has the most invoices?
select count (*) as total_count, billing_country
from invoice
group by billing_country
order by total_count desc

--Q: What are the top 3 values of invoice?
select total from invoice
order by total desc
limit 3

--Q: Which city has the best costumers? We would like to throw a promotional music festival
	--in the city we made more money. Write a query thaat returns one city that has the highest sum of invoice total
	--Return both the city name & sum of all inovice totals.
select sum(total) as invoice_total, billing_city 
from invoice
group by billing_city
order by invoice_total desc

--Q: who has the best costumer? the costumer who has spent the most money will be declared the best customer.
	--write a query that return the person who has  spent the most.
select customer.customer_id, customer.first_name, customer.last_name, sum(invoice.total) as total
from customer
join invoice on customer.customer_id = invoice.customer_id
group by customer.customer_id
order by total desc
limit 1

--Q: Write a query to return a email, fist name, last name & genre of all rock music
	--listeners. Return your list ordered alphabetically by email starting with A.

select distinct first_name, last_name, email 
from customer
join invoice on customer.customer_id = invoice.customer_id
join invoice_line on invoice.invoice_id = invoice_line.invoice_id
where track_id in(
	select track_id from track
	join genre on track.genre_id = genre.genre_id
	where genre.name LIKE 'Rock'
)
order by email;

--Q: Let's invite the artist who have written most number of rock music in our dataset.
	--. write a query that returns the artist name  and total track count of the top
	-- 10 rock bands.
select artist.artist_id, artist.name, count(artist.artist_id) as number_of_songs
from track
join album on album.album_id = track.album_id
join artist on artist.artist_id = album.artist_id
join genre on genre.genre_id = track.genre_id
where genre.name like 'Rock'
group by artist.artist_id
order by number_of_songs desc
limit 10;

--Q: Return all the track names that have a song length longer than the avergae song
	--length. Return the name and millisecond for each track. order by the songs length
	-- with the longest song listed first.

select name,milliseconds
from track
where milliseconds > (
	select avg (milliseconds) as avg_track_ms_lenght
	from track)
order by milliseconds desc;

--Q: Find how much amount spent by each customer on artist? Write a query to
	--Return customer name, artist name and total spent

with best_selling_artist as (
	select artist.artist_id as artist_id, artist.name as artist_name,
	sum(invoice_line.unit_price*invoice_line.quantity) as total_sales
	from invoice_line
	join track on track.track_id = invoice_line.track_id
	join album on album.album_id = track.album_id
	join artist on artist.artist_id = album.artist_id
	group by 1
	order by 3 desc
	limit 1
)
select c customer_id, c.first_name, c.last_name, bsa.artist_name, sum(il.unit_price*il.quantity) as amount_spent
from invoice i
join customer c on c.customer_id = i.customer_id
join invoice_line il on il.invoice_id = i.invoice_id
join track t on t.track_id = il.track_id
join album alb on alb.album_id = t.album_id
join best_selling_artist bsa on bsa.artist_id = alb.artist_id
group by 1, 2, 3, 4
order by 5 desc;

--Q: We want to find out the most popular music genre for each country. we determine
	--the most popular genre as the genre with the highest amount of purchase.
	--write query which returns each country along with the top genre. for the
	--countries where the maximum number of purchases is shared return all genres.

with recursive
	sales_per_country as (
		select count (*) as purchases_per_genre, customer.country, genre.name, genre.genre_id
		from invoice_line
		join invoice on invoice.invoice_id = invoice_line.invoice_id
		join customer on customer.customer_id = invoice.customer_id
		join track on track.track_id = invoice_line.track_id
		join genre on genre.genre_id = track.genre_id
		group by 2,3,4
		order by 2
	),
	max_genre_per_country as (select max(purchases_per_genre) as max_genre_number,
	country from sales_per_country
	group by 2
	order by 2
	)

select sales_per_country.*
from sales_per_country
join max_genre_per_country on sales_per_country.country = max_genre_per_country.country
where sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number

--Q: Write a query that determines the customer that has spent the most on music for each country. Write a query 
	--that returns the country along with the customer and how much they spent. For countries where the top amount 
	--spent is shared, provide all customer who shared this amount.

with customer_with_country as (
	select customer.customer_id,first_name,last_name,billing_country,sum(total) as total_spending,
	row_number() over(partition by billing_country order by sum(total) desc) as rownumber
	from invoice
	join customer on customer.customer_id = invoice.customer_id
	group by 1,2,3,4
	order by 4 asc,5 desc)
select * from customer_with_country where rownumber <= 1
