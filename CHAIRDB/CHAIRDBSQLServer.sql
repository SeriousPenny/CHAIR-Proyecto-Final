/*USE master
GO
DROP DATABASE CHAIRDB
GO
CREATE DATABASE CHAIRDB
GO
USE CHAIRDB
GO*/

/* TABLES */
CREATE TABLE Users(
    nickname VARCHAR(20) NOT NULL,
    [password] VARCHAR(255) NOT NULL,
	salt VARCHAR(255) NULL,
    profileDescription VARCHAR(MAX) NOT NULL DEFAULT '',
    profileLocation VARCHAR(MAX) NOT NULL DEFAULT '',
    birthDate DATE NOT NULL,
    privateProfile BIT DEFAULT 0,
    accountCreationDate DATE NOT NULL DEFAULT GETDATE(),
    [online] BIT DEFAULT 0,
    [admin] BIT DEFAULT 0,
	lastIP VARCHAR(15) NOT NULL DEFAULT '',
    bannedUntil DATETIME NULL,
    banReason VARCHAR(MAX) NOT NULL DEFAULT '',
    CONSTRAINT PK_Users PRIMARY KEY(nickname),
	CONSTRAINT CHK_BirthDateBeforeToday CHECK ( birthDate < GETDATE() ),
	CONSTRAINT CHK_BanUntilBanReason CHECK ( (bannedUntil IS NULL AND banReason = '') OR (bannedUntil IS NOT NULL AND banReason != '') )
)

CREATE TABLE [Messages](
    ID BIGINT IDENTITY(0, 1) NOT NULL,
    [text] VARCHAR(MAX) NOT NULL DEFAULT '',
    sender VARCHAR(20) NOT NULL,
    receiver VARCHAR(20) NOT NULL,
    date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_Messages PRIMARY KEY (ID),
    CONSTRAINT FK_Messages_Users_Sender FOREIGN KEY (sender) REFERENCES Users(nickname) ON UPDATE CASCADE ON DELETE NO ACTION,
    CONSTRAINT FK_Messages_Users_Receiver FOREIGN KEY (receiver) REFERENCES Users(nickname) ON UPDATE NO ACTION ON DELETE NO ACTION
)

-- The acceptedRequestDate is used to determine whether the receiver of the invitation has accepted
-- the request or not.
CREATE TABLE UserFriends(
    user1 VARCHAR(20) NOT NULL,
    user2 VARCHAR(20) NOT NULL,
    acceptedRequestDate DATETIME NULL,
    CONSTRAINT PK_UserFriends PRIMARY KEY (user1, user2),
    CONSTRAINT FK_UserFriends_User1 FOREIGN KEY (user1) REFERENCES Users(nickname) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_UserFriends_User2 FOREIGN KEY (user2) REFERENCES Users(nickname) ON UPDATE NO ACTION ON DELETE NO ACTION
)

CREATE TABLE IPBans(
    [IP] VARCHAR(15) NOT NULL,
	banReason TEXT NULL,
    untilDate DATETIME NULL,
    CONSTRAINT PK_IPBans PRIMARY KEY (IP)
)

CREATE TABLE Games(
    [name] VARCHAR(50) NOT NULL,
	[description] TEXT NOT NULL DEFAULT '',
	developer VARCHAR(MAX) NOT NULL DEFAULT '',
    minimumAge INT NULL,
    releaseDate DATE NULL,
	frontPage BIT DEFAULT 0,
    instructions VARCHAR(MAX) NOT NULL DEFAULT '',
    downloadUrl VARCHAR(MAX) NOT NULL DEFAULT '',
    storeImageUrl VARCHAR(MAX) NOT NULL DEFAULT '',
    libraryImageUrl VARCHAR(MAX) NOT NULL DEFAULT '',
    CONSTRAINT PK_Games PRIMARY KEY (name)
)

CREATE TABLE UserGames(
    [user] VARCHAR(20) NOT NULL,
    game VARCHAR(50) NOT NULL,
    hoursPlayed DECIMAL(10, 3) DEFAULT 0 NOT NULL ,
    acquisitionDate DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
    lastPlayed DATETIME NULL,
	playing BIT DEFAULT 0,
    CONSTRAINT PK_UserGames PRIMARY KEY ([user], game),
    CONSTRAINT FK_UserGames_Users FOREIGN KEY ([user]) REFERENCES Users(nickname) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_UserGames_Games FOREIGN KEY (game) REFERENCES Games(name) ON UPDATE CASCADE ON DELETE CASCADE
)

CREATE TABLE NicknameChanges(
	oldNickname VARCHAR(20) NOT NULL,
	newNickname VARCHAR(20) NOT NULL,
	dateChanged DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
)

/* TRIGGERS 
-- Trigger used to save when a user changes its nickname
GO
CREATE TRIGGER trg_SaveNicknameChange ON Users AFTER UPDATE
AS
BEGIN
	DECLARE @oldNickname VARCHAR(20) = (SELECT nickname FROM deleted)
	DECLARE @newNickname VARCHAR(20) = (SELECT nickname FROM inserted)

	IF(@oldNickname != @newNickname COLLATE Latin1_General_CS_AS)
	BEGIN
		BEGIN TRANSACTION
			INSERT INTO NicknameChanges (oldNickname, newNickname) VALUES (@oldNickname, @newNickname)
		COMMIT
	END
END
GO*/

-- Trigger used to ensure that when an update is made to the frontPage field, all the others games have it set to 0
-- (there can only be one game in the front page) 
GO
CREATE TRIGGER trg_ensureOnlyOneFrontPageGame ON Games AFTER UPDATE
AS
	BEGIN
		IF(UPDATE(frontPage))
		BEGIN
			DECLARE @isFrontPage bit = (SELECT frontPage FROM inserted)
			DECLARE @wasFrontPage bit = (SELECT frontPage FROM deleted)
			IF(@isFrontPage = 1 AND @wasFrontPage = 0)
			BEGIN
				DECLARE @name varchar(50) = (SELECT name FROM inserted)
				UPDATE Games SET frontPage = 0 WHERE name != @name
			END
		END
	END
GO

GO
CREATE TRIGGER trg_updateLastPlayedWhenPlaying ON UserGames AFTER UPDATE
AS
	BEGIN
		IF(UPDATE(playing))
		BEGIN
			DECLARE @isPlaying bit = (SELECT playing FROM inserted)
			DECLARE @wasPlaying bit = (SELECT playing FROM deleted)
			IF((@isPlaying = 1 AND @wasPlaying = 0) OR (@isPlaying = 0 AND @wasPlaying = 1))
			BEGIN
				DECLARE @user varchar(20) = (SELECT [user] FROM inserted)
				DECLARE @game varchar(50) = (SELECT game FROM inserted)
				UPDATE UserGames SET lastPlayed = CURRENT_TIMESTAMP WHERE [user] = @user AND game = @game
			END
		END
	END
GO

/* FUNCTIONS */
-- Function that returns a table with all the friends that play my games for each game
GO
CREATE FUNCTION GetFriendsWhoPlayMyGames (@nickname varchar(20))
RETURNS TABLE
AS
RETURN
	WITH
	MyFriends_CTE (me, friend) AS (

		SELECT user1 AS me, user2 AS friend
		FROM UserFriends
		WHERE user1 = @nickname

		UNION

		SELECT user2 AS me, user1 AS friend
		FROM UserFriends
		WHERE user2 = @nickname
	),

	MyGames_CTE (myname, mygame) as  (
		SELECT [user] AS myname, game as mygame FROM UserGames 
			WHERE [user] = @nickname
	),

	MyFriendsGames_CTE (frname, frgame) as (

	 SELECT [user] AS frname, game as frgame
		FROM myfriends_cte AS M
			JOIN UserGames AS UG 
				ON M.friend = UG.[user]
	),

	MyFriendsThatPlayMyGames_CTE as(

	SELECT *
		FROM MyfriendsGames_CTE AS M
			LEFT JOIN myGames_CTE AS M2
				ON M.frgame = M2.mygame
		WHERE M2.mygame IS NOT NULL


	)

	SELECT U.nickname, frgame, U.privateProfile, U.[online], U.[admin] FROM MyFriendsThatPlayMyGames_CTE AS M
		INNER JOIN Users AS U
			ON M.frname = U.nickname
GO

-- Function that returns all friendships from an user, along with their nicknames, online and admin status
-- and the name of the game they're playing in case they are playing a game, otherwise it's null
GO
CREATE FUNCTION GetFriends (@nickname varchar(20))
RETURNS TABLE
AS
RETURN
	SELECT UF.user1, UF.user2, UF.acceptedRequestDate, U.nickname, U.[online], U.admin, UG.game
		FROM UserFriends AS UF
			INNER JOIN Users AS U
				ON (UF.user1 = U.nickname AND UF.user1 != @nickname) OR (UF.user2 = U.nickname AND UF.user2 != @nickname)
			LEFT JOIN UserGames AS UG
				ON UG.[user] = U.nickname AND UG.playing != 0
		WHERE (user1 = @nickname AND acceptedRequestDate IS NOT NULL) OR (user2 = @nickname AND acceptedRequestDate IS NOT NULL) OR (user2 = @nickname AND acceptedRequestDate IS NULL)
GO

-- Function that returns all games, how many players play each game, and how many are playing it right now
GO
CREATE FUNCTION GetGamesStats ()
RETURNS TABLE
AS
RETURN
	SELECT G.name, COUNT(UG.game) AS numberOfPlayers, SUM(CASE WHEN UG.playing = 1 THEN 1 ELSE 0 END) AS numberOfPlayersPlaying, ISNULL(SUM(UG.hoursPlayed), 0) AS totalHoursPlayed
		FROM Games AS G
			LEFT JOIN UserGames AS UG
				ON G.name = UG.game
		GROUP BY G.name
GO


/* PROCEDURES */
-- Procedure used to insert a new friendship between two users
-- Returns 1 if inserted, 0 if one of the users doesn't exists, -1 if a friendship already exists
GO
CREATE PROCEDURE InsertNewFriendship (@user1 VARCHAR(20), @user2 VARCHAR(20), @status INT OUTPUT)
AS
BEGIN
	IF(EXISTS(SELECT 1 FROM UserFriends WHERE user1 = @user1 AND user2 = @user2 OR user1 = @user2 AND user2 = @user1))
		BEGIN
			SET @status = -1;
		END
	ELSE
		BEGIN
			IF(EXISTS(SELECT 1 FROM Users WHERE nickname = @user1) AND EXISTS(SELECT 1 FROM Users WHERE nickname = @user2))
				BEGIN
					INSERT INTO UserFriends (user1, user2) VALUES (@user1, @user2)
					SET @status = 1
				END
			ELSE
				BEGIN
					SET @status = 0;
				END
		END
		
END
GO

-- Procedure used to ban an user as well as his IP
GO
CREATE PROCEDURE BanUserAndIP (@userToBan VARCHAR(20), @bannedUntil DATETIME, @banReason VARCHAR(MAX), @status INT OUTPUT)
AS
BEGIN
	SET @status = 0
	
	--Ban the user
	UPDATE Users SET bannedUntil = @bannedUntil, banReason = @banReason WHERE nickname = @userToBan

	--Search for his last IP and ban it as well
	DECLARE @IP VARCHAR(15) = (SELECT lastIp FROM Users WHERE nickname = @userToBan)
	IF(EXISTS(SELECT 1 FROM IPBans WHERE [IP] = @IP))
	BEGIN
		UPDATE IPBans SET untilDate = @bannedUntil, banReason = @banReason WHERE [IP] = @IP
		SET @status = 1
	END
	ELSE
	BEGIN
		INSERT INTO IPBans ([IP], banReason, untilDate) VALUES (@IP, @banReason, @bannedUntil)
		SET @status = 1
	END
END
GO

-- Procedure used to pardon an user from his ban
GO
CREATE PROCEDURE PardonUser (@userToPardon VARCHAR(20), @status INT OUTPUT)
AS
BEGIN
	SET @status = 0
	
	--Pardon the user
	UPDATE Users SET bannedUntil = NULL, banReason = '' WHERE nickname = @userToPardon
	SET @status = 1
END
GO

-- Procedure used to pardon an user from his ban and his IP ban
GO
CREATE PROCEDURE PardonUserAndIP (@userToPardon VARCHAR(20), @status INT OUTPUT)
AS
BEGIN
	SET @status = 0
	
	--Pardon the user
	UPDATE Users SET bannedUntil = NULL, banReason = '' WHERE nickname = @userToPardon

	--Get the user's last IP
	DECLARE @IP VARCHAR(15) = (SELECT lastIP FROM Users WHERE nickname = @userToPardon)

	--Pardon the IP
	DELETE FROM IPBans WHERE [IP] = @IP

	SET @status = 1
END
GO