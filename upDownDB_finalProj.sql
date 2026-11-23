/* =====================================================================
   FootballTeam database (SQL Server / T-SQL)
   built from: NFL Data Requirements - NFL Data Dictionary
   order: 1) create database  2) drop keys  3) drop tables
          4) create tables    5) create keys
   safe to re-run
   ===================================================================== */

-- 1) create database
if db_id(N'FootballTeam') is null
    create database FootballTeam;
go

use FootballTeam;
go

-- 2) drop keys (foreign keys, checks, unique keys, primary keys)

-- foreign keys
if object_id(N'ft_teams', N'U') is not null
    alter table ft_teams drop constraint if exists fk_ft_teams_cap;
if object_id(N'ft_teams', N'U') is not null
    alter table ft_teams drop constraint if exists fk_ft_teams_head_coach;
if object_id(N'ft_players', N'U') is not null
    alter table ft_players drop constraint if exists fk_ft_players_team;
if object_id(N'ft_players', N'U') is not null
    alter table ft_players drop constraint if exists fk_ft_players_draft_team;
if object_id(N'ft_coaches', N'U') is not null
    alter table ft_coaches drop constraint if exists fk_ft_coaches_team;
if object_id(N'ft_games', N'U') is not null
    alter table ft_games drop constraint if exists fk_ft_games_home_team;
if object_id(N'ft_games', N'U') is not null
    alter table ft_games drop constraint if exists fk_ft_games_away_team;
if object_id(N'ft_injury_reports', N'U') is not null
    alter table ft_injury_reports drop constraint if exists fk_ft_injury_reports_player;
if object_id(N'ft_statistics', N'U') is not null
    alter table ft_statistics drop constraint if exists fk_ft_statistics_player;
if object_id(N'ft_statistics', N'U') is not null
    alter table ft_statistics drop constraint if exists fk_ft_statistics_game;
if object_id(N'ft_team_seasons', N'U') is not null
    alter table ft_team_seasons drop constraint if exists fk_ft_team_seasons_team;
if object_id(N'ft_team_seasons', N'U') is not null
    alter table ft_team_seasons drop constraint if exists fk_ft_team_seasons_season;

-- check constraints
if object_id(N'ft_league_salary_caps', N'U') is not null
    alter table ft_league_salary_caps drop constraint if exists ck_ft_league_salary_caps_amount;
if object_id(N'ft_players', N'U') is not null
    alter table ft_players drop constraint if exists ck_ft_players_age;
if object_id(N'ft_players', N'U') is not null
    alter table ft_players drop constraint if exists ck_ft_players_pick_number;
if object_id(N'ft_players', N'U') is not null
    alter table ft_players drop constraint if exists ck_ft_players_salary;
if object_id(N'ft_players', N'U') is not null
    alter table ft_players drop constraint if exists ck_ft_players_contract_dates;
if object_id(N'ft_games', N'U') is not null
    alter table ft_games drop constraint if exists ck_ft_games_different_teams;
if object_id(N'ft_injury_reports', N'U') is not null
    alter table ft_injury_reports drop constraint if exists ck_ft_injury_reports_dates;

-- unique keys
if object_id(N'ft_league_salary_caps', N'U') is not null
    alter table ft_league_salary_caps drop constraint if exists uq_ft_league_salary_caps_year;
if object_id(N'ft_teams', N'U') is not null
    alter table ft_teams drop constraint if exists uq_ft_teams_name;
if object_id(N'ft_players', N'U') is not null
    alter table ft_players drop constraint if exists uq_ft_players_draft_year_pick;
if object_id(N'ft_statistics', N'U') is not null
    alter table ft_statistics drop constraint if exists uq_ft_statistics_player_game_stat;
if object_id(N'ft_seasons', N'U') is not null
    alter table ft_seasons drop constraint if exists uq_ft_seasons_year;

-- primary keys
if object_id(N'ft_league_salary_caps', N'U') is not null
    alter table ft_league_salary_caps drop constraint if exists pk_ft_league_salary_caps;
if object_id(N'ft_teams', N'U') is not null
    alter table ft_teams drop constraint if exists pk_ft_teams;
if object_id(N'ft_players', N'U') is not null
    alter table ft_players drop constraint if exists pk_ft_players;
if object_id(N'ft_coaches', N'U') is not null
    alter table ft_coaches drop constraint if exists pk_ft_coaches;
if object_id(N'ft_games', N'U') is not null
    alter table ft_games drop constraint if exists pk_ft_games;
if object_id(N'ft_injury_reports', N'U') is not null
    alter table ft_injury_reports drop constraint if exists pk_ft_injury_reports;
if object_id(N'ft_statistics', N'U') is not null
    alter table ft_statistics drop constraint if exists pk_ft_statistics;
if object_id(N'ft_seasons', N'U') is not null
    alter table ft_seasons drop constraint if exists pk_ft_seasons;
if object_id(N'ft_team_seasons', N'U') is not null
    alter table ft_team_seasons drop constraint if exists pk_ft_team_seasons;

-- leftovers from the earlier versions of this script (old names)
if object_id(N'dbo.Team', N'U') is not null
    alter table dbo.Team drop constraint if exists FK_Team_LeagueSalaryCap;
if object_id(N'dbo.Team', N'U') is not null
    alter table dbo.Team drop constraint if exists FK_Team_HeadCoach;
if object_id(N'dbo.Player', N'U') is not null
    alter table dbo.Player drop constraint if exists FK_Player_Team;
if object_id(N'dbo.Player', N'U') is not null
    alter table dbo.Player drop constraint if exists FK_Player_DraftTeam;
if object_id(N'dbo.Coach', N'U') is not null
    alter table dbo.Coach drop constraint if exists FK_Coach_Team;
if object_id(N'dbo.Game', N'U') is not null
    alter table dbo.Game drop constraint if exists FK_Game_HomeTeam;
if object_id(N'dbo.Game', N'U') is not null
    alter table dbo.Game drop constraint if exists FK_Game_AwayTeam;
if object_id(N'dbo.InjuryReport', N'U') is not null
    alter table dbo.InjuryReport drop constraint if exists FK_InjuryReport_Player;
if object_id(N'dbo.Statistic', N'U') is not null
    alter table dbo.Statistic drop constraint if exists FK_Statistic_Player;
if object_id(N'dbo.Statistic', N'U') is not null
    alter table dbo.Statistic drop constraint if exists FK_Statistic_Game;
if object_id(N'dbo.TeamSeason', N'U') is not null
    alter table dbo.TeamSeason drop constraint if exists FK_TeamSeason_Team;
if object_id(N'dbo.TeamSeason', N'U') is not null
    alter table dbo.TeamSeason drop constraint if exists FK_TeamSeason_Season;
if object_id(N'dbo.Contract', N'U') is not null
    alter table dbo.Contract drop constraint if exists FK_Contract_Player;
if object_id(N'dbo.TeamOwner', N'U') is not null
    alter table dbo.TeamOwner drop constraint if exists FK_TeamOwner_Team;
if object_id(N'dbo.PlayerPosition', N'U') is not null
    alter table dbo.PlayerPosition drop constraint if exists FK_PlayerPosition_Player;
if object_id(N'dbo.InjuryReportType', N'U') is not null
    alter table dbo.InjuryReportType drop constraint if exists FK_InjuryReportType_InjuryReport;
if object_id(N'dbo.DraftPickPosition', N'U') is not null
    alter table dbo.DraftPickPosition drop constraint if exists FK_DraftPickPosition_DraftPick;
if object_id(N'dbo.DraftPick', N'U') is not null
    alter table dbo.DraftPick drop constraint if exists FK_DraftPick_Team;
if object_id(N'dbo.DraftPick', N'U') is not null
    alter table dbo.DraftPick drop constraint if exists FK_DraftPick_Player;
go

-- 3) drop tables (children first)
drop table if exists dbo.Contract;  -- earlier version
drop table if exists dbo.DraftPickPosition;  -- earlier version
drop table if exists dbo.DraftPick;  -- earlier version
drop table if exists dbo.InjuryReportType;  -- earlier version
drop table if exists dbo.PlayerPosition;  -- earlier version
drop table if exists dbo.TeamOwner;  -- earlier version
drop table if exists dbo.TeamSeason;  -- earlier version
drop table if exists dbo.Season;  -- earlier version
drop table if exists dbo.Statistic;  -- earlier version
drop table if exists dbo.InjuryReport;  -- earlier version
drop table if exists dbo.Game;  -- earlier version
drop table if exists dbo.Coach;  -- earlier version
drop table if exists dbo.Player;  -- earlier version
drop table if exists dbo.Team;  -- earlier version
drop table if exists dbo.LeagueSalaryCap;  -- earlier version
drop table if exists ft_team_seasons;
drop table if exists ft_seasons;
drop table if exists ft_statistics;
drop table if exists ft_injury_reports;
drop table if exists ft_games;
drop table if exists ft_coaches;
drop table if exists ft_players;
drop table if exists ft_teams;
drop table if exists ft_league_salary_caps;
go

-- 4) create tables
create table ft_league_salary_caps (
    cap_id int identity not null,
    cap_year int not null,
    cap_amount decimal(15,2) not null
);

create table ft_teams (
    team_id int identity not null,
    team_name varchar(100) not null,
    team_city varchar(100) not null,
    team_stadium varchar(150) not null,
    team_primary_owner varchar(100) not null,
    team_general_manager varchar(100) not null,
    team_head_coach_id int null,
    team_cap_id int not null
);

create table ft_players (
    player_id int identity not null,
    player_first_name varchar(50) not null,
    player_last_name varchar(50) not null,
    player_position varchar(50) not null,
    player_age int not null,
    player_weight decimal(5,1) null,
    player_height decimal(5,1) null,
    player_team_id int not null,
    player_draft_year int not null,
    player_pick_number int not null,
    player_draft_team_id int not null,
    player_salary decimal(15,2) not null,
    player_contract_sign_date date not null,
    player_contract_expiration_date date not null
);

create table ft_coaches (
    coach_id int identity not null,
    coach_first_name varchar(50) not null,
    coach_last_name varchar(50) not null,
    coach_role varchar(50) not null,
    coach_team_id int not null
);

create table ft_games (
    game_id int identity not null,
    game_date date not null,
    game_home_team_id int not null,
    game_away_team_id int not null,
    game_stadium varchar(150) not null
);

create table ft_injury_reports (
    injury_report_id int identity not null,
    injury_report_player_id int not null,
    injury_report_injury_date date not null,
    injury_report_return_date date null,
    injury_report_timeline varchar(100) null,
    injury_report_type varchar(100) not null
);

create table ft_statistics (
    stat_id int identity not null,
    stat_player_id int not null,
    stat_game_id int not null,
    stat_name varchar(50) not null,
    stat_total decimal(10,2) null,
    stat_games_played bit not null
);

create table ft_seasons (
    season_id int identity not null,
    season_year int not null
);

create table ft_team_seasons (
    team_season_team_id int not null,
    team_season_season_id int not null
);

go

-- 5) create keys
-- primary keys
alter table ft_league_salary_caps
    add constraint pk_ft_league_salary_caps primary key (cap_id);
alter table ft_teams
    add constraint pk_ft_teams primary key (team_id);
alter table ft_players
    add constraint pk_ft_players primary key (player_id);
alter table ft_coaches
    add constraint pk_ft_coaches primary key (coach_id);
alter table ft_games
    add constraint pk_ft_games primary key (game_id);
alter table ft_injury_reports
    add constraint pk_ft_injury_reports primary key (injury_report_id);
alter table ft_statistics
    add constraint pk_ft_statistics primary key (stat_id);
alter table ft_seasons
    add constraint pk_ft_seasons primary key (season_id);
alter table ft_team_seasons
    add constraint pk_ft_team_seasons primary key (team_season_team_id, team_season_season_id);

-- unique keys
alter table ft_league_salary_caps
    add constraint uq_ft_league_salary_caps_year unique (cap_year);
alter table ft_teams
    add constraint uq_ft_teams_name unique (team_name);
alter table ft_players
    add constraint uq_ft_players_draft_year_pick unique (player_draft_year, player_pick_number);
alter table ft_statistics
    add constraint uq_ft_statistics_player_game_stat unique (stat_player_id, stat_game_id, stat_name);
alter table ft_seasons
    add constraint uq_ft_seasons_year unique (season_year);

-- check constraints
alter table ft_league_salary_caps
    add constraint ck_ft_league_salary_caps_amount check (cap_amount > 0);
alter table ft_players
    add constraint ck_ft_players_age check (player_age > 0);
alter table ft_players
    add constraint ck_ft_players_pick_number check (player_pick_number > 0);
alter table ft_players
    add constraint ck_ft_players_salary check (player_salary >= 0);
alter table ft_players
    add constraint ck_ft_players_contract_dates check (player_contract_expiration_date > player_contract_sign_date);
alter table ft_games
    add constraint ck_ft_games_different_teams check (game_home_team_id <> game_away_team_id);
alter table ft_injury_reports
    add constraint ck_ft_injury_reports_dates check (injury_report_return_date is null or injury_report_return_date >= injury_report_injury_date);

-- foreign keys
alter table ft_teams
    add constraint fk_ft_teams_cap foreign key (team_cap_id)
        references ft_league_salary_caps (cap_id);
alter table ft_teams
    add constraint fk_ft_teams_head_coach foreign key (team_head_coach_id)
        references ft_coaches (coach_id);
alter table ft_players
    add constraint fk_ft_players_team foreign key (player_team_id)
        references ft_teams (team_id);
alter table ft_players
    add constraint fk_ft_players_draft_team foreign key (player_draft_team_id)
        references ft_teams (team_id);
alter table ft_coaches
    add constraint fk_ft_coaches_team foreign key (coach_team_id)
        references ft_teams (team_id);
alter table ft_games
    add constraint fk_ft_games_home_team foreign key (game_home_team_id)
        references ft_teams (team_id);
alter table ft_games
    add constraint fk_ft_games_away_team foreign key (game_away_team_id)
        references ft_teams (team_id);
alter table ft_injury_reports
    add constraint fk_ft_injury_reports_player foreign key (injury_report_player_id)
        references ft_players (player_id);
alter table ft_statistics
    add constraint fk_ft_statistics_player foreign key (stat_player_id)
        references ft_players (player_id);
alter table ft_statistics
    add constraint fk_ft_statistics_game foreign key (stat_game_id)
        references ft_games (game_id);
alter table ft_team_seasons
    add constraint fk_ft_team_seasons_team foreign key (team_season_team_id)
        references ft_teams (team_id);
alter table ft_team_seasons
    add constraint fk_ft_team_seasons_season foreign key (team_season_season_id)
        references ft_seasons (season_id);
go