--View our dataset--
SELECT * 
FROM IMDBTop250MoviesCleanedIMDBTop250Movies;


--Change table name--
ALTER TABLE  IMDBTop250MoviesCleanedIMDBTop250Movies RENAME TO Movies


SELECT * 
FROM Movies


--Top 5 budgeted movies--
SELECT name, budget
FROM Movies
ORDER BY budget DESC
LIMIT 5


‘We can see there is an obvious outlier with the top movie Princess Mononoke. By doing a quick google search we can see the actual movie budget matches this number in Japanese Yen, Not in USD. So lets fix that to the USD equivalent $23,500,000.
3 Idiots as well is a foreign movie so lets see the converted rate for ₹55 crore. It is actually just under 6.7 million.
Because the other top 5 movies are from the US, no other adjustments are necessary'


--Princess Mononoke update--
UPDATE Movies
SET budget = REPLACE(budget, 2400000000, 23500000)

--3 Idiots Update--
UPDATE Movies 
SET budget = REPLACE(budget, 550000000, 6700000)


--retrieve the outcome--
SELECT name, budget
FROM Movies
ORDER BY budget DESC
LIMIT 5


--Top 5 rated movies--
SELECT name, rating
FROM Movies
ORDER BY rating DESC
LIMIT 5

--top 5 box office hits--
SELECT name, box_office
 FROM Movies
 GROUP BY name 
 ORDER BY box_office DESC
 LIMIT 5


--top 10 highest profit--
 SELECT name, budget, box_office, (box_office - budget) AS profit 
 FROM Movies
 ORDER BY profit DESC
 LIMIT 10



 --Most popular genres--
SELECT genre, COUNT(*) AS genre_count
FROM (
  SELECT TRIM(value) AS genre
  FROM Movies
  CROSS JOIN json_each('["' || REPLACE(genre, ',', '","') || '"]')
)
GROUP BY genre
ORDER BY genre_count DESC
LIMIT 5


 --top 10 directors--
 SELECT directors, COUNT(*) AS Number_of_movies
 FROM Movies
 GROUP BY directors
 ORDER BY COUNT(*) DESC
 Limit 10


--how many movies in each rating category--
Select certificate, count(*) AS total
FROM Movies
group by certificate 
order by total DESC

 --Best years for movies--
 SELECT year, COUNT(year) AS Number_of_Movies_Per_Year
 FROM Movies
 GROUP BY year
 ORDER BY COUNT(year) DESC
 Limit 10

--how many movies in each decade--

SELECT 
    year/10 * 10 + 1 as decade_start,
    year/10 * 10 + 10 as decade_end,
    COUNT(year) as number_of_movies
FROM  Movies
GROUP BY year/10 
ORDER BY decade_start

**for visualization purposes it makes sense to keep the decade in one column so combining them utilizing the concat function gives us that ability 

SELECT
    decade_start || ' - ' || decade_end as decade,
    COUNT(year) as number_of_movies
FROM (
    SELECT 
        (year/10) * 10 + 1 as decade_start,
        (year/10) * 10 + 10 as decade_end,
        year
    FROM Movies
) AS subquery
GROUP BY decade_start
ORDER BY decade_start

--most popular movie genre in each decade--
WITH genre_counts AS (
  SELECT genre, COUNT(*) AS genre_count, year
  FROM (
    SELECT TRIM(value) AS genre, year
    FROM Movies
    CROSS JOIN json_each('["' || REPLACE(genre, ',', '","') || '"]')
  )
  GROUP BY genre, year
), decade_max_genre AS (
  SELECT d.decade_start, d.decade_end, gc.genre,
         ROW_NUMBER() OVER (PARTITION BY d.decade_start ORDER BY gc.genre_count DESC) AS rn
  FROM (
    SELECT 
      year/10 * 10 + 1 AS decade_start,
      year/10 * 10 + 10 AS decade_end
    FROM Movies
    GROUP BY year/10
  ) d
  JOIN genre_counts gc ON gc.year >= d.decade_start AND gc.year <= d.decade_end
)
SELECT decade_start, decade_end, genre
FROM decade_max_genre
WHERE rn = 1
ORDER BY decade_start

** as with the previous query for visualization purposes lets combine the decade_start and decade_end into 1 column 

WITH genre_counts AS (
  SELECT genre, COUNT(*) AS genre_count, year
  FROM (
    SELECT TRIM(value) AS genre, year
    FROM Movies
    CROSS JOIN json_each('["' || REPLACE(genre, ',', '","') || '"]')
  )
  GROUP BY genre, year
), decade_max_genre AS (
  SELECT 
    d.decade_start || ' - ' || d.decade_end AS decade,
    gc.genre,
    ROW_NUMBER() OVER (PARTITION BY d.decade_start ORDER BY gc.genre_count DESC) AS rn
  FROM (
    SELECT 
      (year/10) * 10 + 1 AS decade_start,
      (year/10) * 10 + 10 AS decade_end
    FROM Movies
    GROUP BY year/10
  ) d
  JOIN genre_counts gc ON gc.year >= d.decade_start AND gc.year <= d.decade_end
)
SELECT decade, genre
FROM decade_max_genre
WHERE rn = 1
ORDER BY decade