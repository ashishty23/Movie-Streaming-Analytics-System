-- Users Table
CREATE TABLE Users (
    user_id INT PRIMARY KEY,
    name VARCHAR(100),
    country VARCHAR(50),
    signup_date DATE
);

-- Movies Table
CREATE TABLE Movies (
    movie_id INT PRIMARY KEY,
    title VARCHAR(100),
    genre VARCHAR(50),
    release_year INT,
    duration_minutes INT
);

-- Subscriptions Table
CREATE TABLE Subscriptions (
    subscription_id INT PRIMARY KEY,
    user_id INT,
    plan_type VARCHAR(20), -- Basic, Standard, Premium
    start_date DATE,
    end_date DATE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

-- WatchHistory Table
CREATE TABLE WatchHistory (
    watch_id INT PRIMARY KEY,
    user_id INT,
    movie_id INT,
    watch_date DATE,
    watch_duration INT, -- minutes watched
    rating INT, -- 1-5 stars
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (movie_id) REFERENCES Movies(movie_id)
);

-- users
INSERT INTO Users (user_id, name, country, signup_date) VALUES
(1, 'Alice', 'USA', '2024-01-10'),
(2, 'Bob', 'India', '2024-02-15'),
(3, 'Charlie', 'UK', '2024-03-05'),
(4, 'David', 'USA', '2024-03-12'),
(5, 'Eve', 'India', '2024-04-01'),
(6, 'Frank', 'Canada', '2024-04-20'),
(7, 'Grace', 'UK', '2024-05-02'),
(8, 'Hank', 'USA', '2024-05-15'),
(9, 'Ivy', 'Canada', '2024-06-01'),
(10, 'Jack', 'India', '2024-06-10');

-- Movies
INSERT INTO Movies (movie_id, title, genre, release_year, duration_minutes) VALUES
(101, 'Inception', 'Sci-Fi', 2010, 148),
(102, 'Titanic', 'Romance', 1997, 195),
(103, 'The Dark Knight', 'Action', 2008, 152),
(104, 'Interstellar', 'Sci-Fi', 2014, 169),
(105, 'Avengers: Endgame', 'Action', 2019, 181),
(106, 'Joker', 'Drama', 2019, 122),
(107, 'Sholay', 'Action', 1975, 204),
(108, 'DDLJ', 'Romance', 1995, 190),
(109, 'The Godfather', 'Crime', 1972, 175),
(110, 'Parasite', 'Thriller', 2019, 132);

-- Subscriptions
INSERT INTO Subscriptions (subscription_id, user_id, plan_type, start_date, end_date) VALUES
(201, 1, 'Premium', '2024-01-10', '2025-01-10'),
(202, 2, 'Standard', '2024-02-15', '2024-08-15'),
(203, 3, 'Basic', '2024-03-05', '2025-03-05'),
(204, 4, 'Premium', '2024-03-12', '2025-03-12'),
(205, 5, 'Basic', '2024-04-01', '2024-10-01'),
(206, 6, 'Standard', '2024-04-20', '2025-04-20'),
(207, 7, 'Premium', '2024-05-02', '2025-05-02'),
(208, 8, 'Basic', '2024-05-15', '2024-11-15'),
(209, 9, 'Standard', '2024-06-01', '2025-06-01'),
(210, 10, 'Premium', '2024-06-10', '2025-06-10');

-- WatchHistory
INSERT INTO WatchHistory (watch_id, user_id, movie_id, watch_date, watch_duration, rating) VALUES
(301, 1, 101, '2024-01-15', 140, 5),
(302, 1, 103, '2024-02-01', 150, 4),
(303, 2, 107, '2024-02-20', 180, 5),
(304, 2, 108, '2024-03-01', 170, 4),
(305, 3, 109, '2024-03-10', 160, 5),
(306, 3, 110, '2024-03-12', 120, 4),
(307, 4, 104, '2024-03-20', 160, 5),
(308, 5, 102, '2024-04-10', 190, 3),
(309, 5, 108, '2024-04-15', 185, 4),
(310, 6, 105, '2024-05-01', 170, 5),
(311, 6, 106, '2024-05-05', 120, 4),
(312, 7, 101, '2024-05-12', 130, 5),
(313, 7, 103, '2024-05-20', 150, 4),
(314, 8, 107, '2024-06-01', 200, 5),
(315, 8, 105, '2024-06-05', 175, 4),
(316, 9, 109, '2024-06-15', 165, 5),
(317, 10, 110, '2024-06-20', 130, 3),
(318, 10, 102, '2024-06-25', 180, 4);


-- Find the Top 3 most-watched movies per country
    WITH MovieWatch AS (
      SELECT u.country, m.title, COUNT(*) AS total_views
      FROM WatchHistory w
      JOIN Users u ON w.user_id = u.user_id
      JOIN Movies m ON w.movie_id = m.movie_id
      GROUP BY u.country, m.title
    )
    SELECT country, title, total_views
    FROM (
      SELECT country, title, total_views,
             RANK() OVER(PARTITION BY country ORDER BY total_views DESC) AS rnk
      FROM MovieWatch
    ) ranked
    WHERE rnk <= 3;

-- Find the most loyal users (highest average watch time per session)
    SELECT user_id, 
           AVG(watch_duration) AS avg_watch_time,
           RANK() OVER (ORDER BY AVG(watch_duration) DESC) AS loyalty_rank
    FROM WatchHistory
    GROUP BY user_id;

-- Find churned users (users whose subscription ended and didn’t watch any movie afterward)
    SELECT s.user_id
    FROM Subscriptions s
    LEFT JOIN WatchHistory w
      ON s.user_id = w.user_id
     AND w.watch_date > s.end_date
    WHERE w.watch_id IS NULL;
-- Find the genre preference per user (most watched genre per user)
    WITH GenreCount AS (
      SELECT u.user_id, m.genre, COUNT(*) AS watch_count
      FROM WatchHistory w
      JOIN Users u ON w.user_id = u.user_id
      JOIN Movies m ON w.movie_id = m.movie_id
      GROUP BY u.user_id, m.genre
    )
    SELECT user_id, genre
    FROM (
      SELECT user_id, genre, watch_count,
             RANK() OVER(PARTITION BY user_id ORDER BY watch_count DESC) AS rnk
      FROM GenreCount
    ) ranked
    WHERE rnk = 1;

-- Calculate average rating per movie and rank movies within each genre
    SELECT m.genre, m.title,
           AVG(w.rating) AS avg_rating,
           RANK() OVER(PARTITION BY m.genre ORDER BY AVG(w.rating) DESC) AS genre_rank
    FROM WatchHistory w
    JOIN Movies m ON w.movie_id = m.movie_id
    GROUP BY m.genre, m.title;

-- Find the monthly revenue per plan (assume fixed prices: Basic=200, Standard=400, Premium=600)
    SELECT DATE_TRUNC('month', start_date) AS month,
           plan_type,
           COUNT(*) *
           CASE plan_type
             WHEN 'Basic' THEN 200
             WHEN 'Standard' THEN 400
             WHEN 'Premium' THEN 600
           END AS monthly_revenue
    FROM Subscriptions
    GROUP BY DATE_TRUNC('month', start_date), plan_type
    ORDER BY month, plan_type;

-- Find the number of users in each country.
    SELECT country, COUNT(*) AS total_users
    FROM Users
    GROUP BY country;

-- Find the total number of movies per genre.
    SELECT genre, COUNT(*) AS total_movies
    FROM Movies
    GROUP BY genre;

-- Get users who signed up in the last 6 months.
    SELECT *
    FROM Users
    WHERE signup_date >= CURRENT_DATE - INTERVAL '6 months';

-- Find the total watch time per user.
    SELECT user_id, SUM(watch_duration) AS total_watch_time
    FROM WatchHistory
    GROUP BY user_id;

-- Find all movies that have never been watched.
    SELECT m.movie_id, m.title
    FROM Movies m
    LEFT JOIN WatchHistory w ON m.movie_id = w.movie_id
    WHERE w.watch_id IS NULL;

-- Find each user's binge-watching streak (max consecutive days watched).
    WITH DailyWatch AS (
      SELECT user_id, watch_date,
             LAG(watch_date) OVER(PARTITION BY user_id ORDER BY watch_date) AS prev_day
      FROM WatchHistory
    )
    SELECT user_id, MAX(streak) AS longest_streak
    FROM (
      SELECT user_id,
             CASE WHEN watch_date = prev_day + INTERVAL '1 day'
                  THEN 1 ELSE 0 END AS streak_flag
      FROM DailyWatch
    ) t
    JOIN (
      SELECT user_id, COUNT(*) AS streak
      FROM DailyWatch
      GROUP BY user_id
    ) s USING(user_id)
    GROUP BY user_id;
-- Find movies with the highest completion rate (watch_duration / duration_minutes).
    SELECT m.title,
           AVG(w.watch_duration * 1.0 / m.duration_minutes) AS avg_completion_rate
    FROM WatchHistory w
    JOIN Movies m ON w.movie_id = m.movie_id
    GROUP BY m.title
    ORDER BY avg_completion_rate DESC;

-- Find the most popular subscription plan per month.
    WITH MonthlyPlans AS (
      SELECT DATE_TRUNC('month', start_date) AS month, plan_type, COUNT(*) AS subs
      FROM Subscriptions
      GROUP BY DATE_TRUNC('month', start_date), plan_type
    )
    SELECT month, plan_type, subs
    FROM (
      SELECT month, plan_type, subs,
             RANK() OVER(PARTITION BY month ORDER BY subs DESC) AS rnk
      FROM MonthlyPlans
    ) ranked
    WHERE rnk = 1;

-- Find the users who rated at least 5 movies but have an average rating below 3.
    SELECT user_id, AVG(rating) AS avg_rating, COUNT(*) AS total_reviews
    FROM WatchHistory
    WHERE rating IS NOT NULL
    GROUP BY user_id
    HAVING COUNT(*) >= 5 AND AVG(rating) < 3;

-- Find the top 5 most active users each year.
    WITH YearlyActivity AS (
      SELECT user_id, EXTRACT(YEAR FROM watch_date) AS yr, COUNT(*) AS total_sessions
      FROM WatchHistory
      GROUP BY user_id, EXTRACT(YEAR FROM watch_date)
    )
    SELECT yr, user_id, total_sessions
    FROM (
      SELECT yr, user_id, total_sessions,
             RANK() OVER(PARTITION BY yr ORDER BY total_sessions DESC) AS rnk
      FROM YearlyActivity
    ) ranked
    WHERE rnk <= 5;













