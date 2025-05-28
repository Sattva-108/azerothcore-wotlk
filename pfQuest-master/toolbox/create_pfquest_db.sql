-- Create pfquest database and load DBC tables
CREATE DATABASE IF NOT EXISTS pfquest;
USE pfquest;

-- Grant permissions to acore user
GRANT ALL PRIVILEGES ON pfquest.* TO 'acore'@'localhost';
FLUSH PRIVILEGES;
