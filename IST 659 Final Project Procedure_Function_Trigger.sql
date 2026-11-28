use FootballTeam

go

/*
Procedures:
-- function  f_team_cap_space
               how much salary cap room a team has for a league year.
               used by the cap analyst before any signing.
     procedure p_sign_player_contract
               the GM signs / re-signs / poaches a player. the signing
               is blocked if it would put the team over the cap in any
               league year the contract covers.
     trigger   t_statistics_participation_check
               protects the stat data. a stat line is rejected if the
               player's team did not play in that game, or if the player
               was on the injury report (out) on game day.
*/


--Sample Data Inserts 

if not exists (select 1 from ft_league_salary_caps where cap_year = 2025)
    insert into ft_league_salary_caps (cap_year, cap_amount)
        values (2025, 279200000.00);

-- teams
insert into ft_teams (team_name, team_city, team_stadium, team_primary_owner, team_general_manager, team_head_coach_id, team_cap_id)
select v.team_name, v.team_city, v.team_stadium, v.team_primary_owner, v.team_general_manager, null,
       (select cap_id from ft_league_salary_caps where cap_year = 2025)
from (values
    ('Eagles',  'Philadelphia', 'Lincoln Financial Field', 'Jeffrey Lurie', 'Howie Roseman'),
    ('Cowboys', 'Dallas',       'AT&T Stadium',            'Jerry Jones',   'Jerry Jones'),
    ('Giants',  'New York',     'MetLife Stadium',         'John Mara',     'Joe Schoen')
) as v (team_name, team_city, team_stadium, team_primary_owner, team_general_manager)
where not exists (select 1 from ft_teams t where t.team_name = v.team_name);

insert into ft_players (player_first_name, player_last_name, player_position, player_age, player_weight, player_height,
                        player_team_id, player_draft_year, player_pick_number, player_draft_team_id,
                        player_salary, player_contract_sign_date, player_contract_expiration_date)
select v.first_name, v.last_name, v.position, v.age, v.weight, v.height,
       (select team_id from ft_teams where team_name = v.team_name),
       v.draft_year, v.pick_number,
       (select team_id from ft_teams where team_name = v.draft_team_name),
       v.salary, v.sign_date, v.expiration_date
from (values
    ('Jalen',  'Hurts',    'QB', 27, 223.0, 73.0, 'Eagles',  2020,  53, 'Eagles',  51000000.00, cast('2024-04-15' as date), cast('2029-02-28' as date)),
    ('Saquon', 'Barkley',  'RB', 28, 233.0, 72.0, 'Eagles',  2018,   2, 'Giants',  12600000.00, cast('2024-03-14' as date), cast('2027-02-28' as date)),
    ('CeeDee', 'Lamb',     'WR', 26, 200.0, 74.0, 'Cowboys', 2020,  17, 'Cowboys', 34000000.00, cast('2024-08-26' as date), cast('2029-02-28' as date)),
    ('Dak',    'Prescott', 'QB', 32, 238.0, 74.0, 'Cowboys', 2016, 135, 'Cowboys', 60000000.00, cast('2024-09-08' as date), cast('2029-02-28' as date))
) as v (first_name, last_name, position, age, weight, height, team_name, draft_year, pick_number, draft_team_name, salary, sign_date, expiration_date)
where not exists (select 1 from ft_players p
                  where p.player_draft_year = v.draft_year and p.player_pick_number = v.pick_number);

-- games
insert into ft_games (game_date, game_home_team_id, game_away_team_id, game_stadium)
select v.game_date,
       (select team_id from ft_teams where team_name = v.home_team),
       (select team_id from ft_teams where team_name = v.away_team),
       v.stadium
from (values
    (cast('2025-09-04' as date), 'Eagles',  'Cowboys', 'Lincoln Financial Field'),
    (cast('2025-09-14' as date), 'Cowboys', 'Giants',  'AT&T Stadium')
) as v (game_date, home_team, away_team, stadium)
where not exists (select 1 from ft_games g
                  where g.game_date = v.game_date
                    and g.game_home_team_id = (select team_id from ft_teams where team_name = v.home_team));
go

/* ---------------------------------------------------------------------
   1) FUNCTION: f_team_cap_space
   purpose: returns a team's remaining cap room for an NFL league year.
            the league year starts March 1, so the 2025 league year runs
            2025-03-01 through 2026-02-28. a contract counts against the
            cap if it is active at any point in that window.
   returns: cap amount - committed salaries, or null if no cap is on
            file for that year.
   --------------------------------------------------------------------- */
drop function if exists dbo.f_team_cap_space;
go

create function f_team_cap_space (
    @team_id int,
    @cap_year int
) returns decimal(15,2)
as begin
    declare @cap decimal(15,2);
    declare @committed decimal(15,2);
    select @cap = cap_amount
        from ft_league_salary_caps
        where cap_year = @cap_year;
    if @cap is null return null;
    select @committed = isnull(sum(player_salary), 0)
        from ft_players
        where player_team_id = @team_id
          and player_contract_sign_date < datefromparts(@cap_year + 1, 3, 1)
          and player_contract_expiration_date >= datefromparts(@cap_year, 3, 1);
    return @cap - @committed;
end
go



/* ---------------------------------------------------------------------
   2) PROCEDURE: p_sign_player_contract
   purpose: the GM signs a player to a new contract (re-signing his own
            player or signing a player from another team). the contract
            is checked against the cap for every league year it covers
            that has a cap on file. if the team can't afford it, nothing
            changes.
   re-signing: the player's old salary is credited back, since the new
            deal replaces it.
   inputs:  @player_id, @team_id, @annual_salary, @sign_date,
            @expiration_date
   --------------------------------------------------------------------- */
drop procedure if exists dbo.p_sign_player_contract;
go

create procedure p_sign_player_contract (
    @player_id int,
    @team_id int,
    @annual_salary decimal(15,2),
    @sign_date date,
    @expiration_date date
) as begin
    begin try
        declare @msg nvarchar(2048);
        declare @first_league_year int;
        declare @last_league_year int;
        declare @short_year int;
        declare @short_space decimal(15,2);
        -- input checks
        if not exists (select 1 from ft_players where player_id = @player_id)
            throw 50101, 'Signing blocked: player not found.', 1;
        if not exists (select 1 from ft_teams where team_id = @team_id)
            throw 50102, 'Signing blocked: team not found.', 1;
        if @annual_salary is null or @annual_salary < 0
            throw 50103, 'Signing blocked: salary must be zero or more.', 1;
        if @expiration_date <= @sign_date
            throw 50104, 'Signing blocked: contract must expire after it is signed.', 1;
        -- league years the contract covers (league year starts March 1)
        set @first_league_year = case when month(@sign_date) >= 3 then year(@sign_date) else year(@sign_date) - 1 end;
        set @last_league_year  = case when month(@expiration_date) >= 3 then year(@expiration_date) else year(@expiration_date) - 1 end;
        begin transaction;
            if not exists (select 1 from ft_league_salary_caps where cap_year = @first_league_year) begin
                set @msg = concat('Signing blocked: no salary cap is on file for the ', @first_league_year, ' league year.');
                throw 50105, @msg, 1;
            end
            -- first covered league year where the team can't afford the deal
            select top 1
                   @short_year  = c.cap_year,
                   @short_space = dbo.f_team_cap_space(@team_id, c.cap_year) + isnull(cur.old_salary, 0)
                from ft_league_salary_caps c
                outer apply (
                    -- credit back the player's current deal if he is re-signing with this team
                    select p.player_salary as old_salary
                        from ft_players p
                        where p.player_id = @player_id
                          and p.player_team_id = @team_id
                          and p.player_contract_sign_date < datefromparts(c.cap_year + 1, 3, 1)
                          and p.player_contract_expiration_date >= datefromparts(c.cap_year, 3, 1)
                ) as cur
                where c.cap_year between @first_league_year and @last_league_year
                  and dbo.f_team_cap_space(@team_id, c.cap_year) + isnull(cur.old_salary, 0) < @annual_salary
                order by c.cap_year;
            if @short_year is not null begin
                set @msg = concat('Signing blocked: this contract puts the team over the ', @short_year,
                                  ' salary cap. Cap space available: $', format(@short_space, 'N2'),
                                  '. Salary offered: $', format(@annual_salary, 'N2'), '.');
                throw 50106, @msg, 1;
            end
            -- sign the player
            update ft_players
                set player_team_id = @team_id,
                    player_salary = @annual_salary,
                    player_contract_sign_date = @sign_date,
                    player_contract_expiration_date = @expiration_date
                where player_id = @player_id;

            if @@rowcount <> 1
                throw 50107, 'Signing blocked: error updating the player contract.', 1;

        commit;

        -- confirmation for the front office
        select p.player_first_name + ' ' + p.player_last_name as player,
               t.team_name as team,
               p.player_salary as annual_salary,
               p.player_contract_sign_date as sign_date,
               p.player_contract_expiration_date as expiration_date,
               dbo.f_team_cap_space(t.team_id, @first_league_year) as cap_space_remaining
            from ft_players p
            join ft_teams t on t.team_id = p.player_team_id
            where p.player_id = @player_id;
    end try
    begin catch
        if @@trancount > 0 rollback;
        throw;
    end catch
end
go


/* ---------------------------------------------------------------------
   3) TRIGGER: t_statistics_participation_check
   purpose: keeps stat data clean (like a participation data check).
            rejects any stat row where:
              a) the player's team was neither the home nor away team
              b) the player was on the injury report on game day
                 (injured before the game, not yet returned)
   works on multi-row inserts/updates. throwing inside a trigger rolls
   back the whole statement, so no bad rows are saved.
   note: rule a uses the player's current team.
   --------------------------------------------------------------------- */
drop trigger if exists t_statistics_participation_check;
go

create trigger t_statistics_participation_check
    on ft_statistics
    after insert, update
as begin
    if not exists (select 1 from inserted) return;
    -- a) player's team has to be in the game
    if exists (
        select 1
            from inserted i
            join ft_players p on p.player_id = i.stat_player_id
            join ft_games g on g.game_id = i.stat_game_id
            where p.player_team_id not in (g.game_home_team_id, g.game_away_team_id)
    )
        throw 50111, 'Stat rejected: the player''s team did not play in this game.', 1;

    -- b) player can't be on the injury report on game day
    if exists (
        select 1
            from inserted i
            join ft_games g on g.game_id = i.stat_game_id
            join ft_injury_reports r on r.injury_report_player_id = i.stat_player_id
            where r.injury_report_injury_date < g.game_date
              and (r.injury_report_return_date is null or r.injury_report_return_date > g.game_date)
    )
        throw 50112, 'Stat rejected: the player was on the injury report for this game.', 1;
end
go


/* =====================================================================
   4) DEMO SCRIPTS
   each failing demo is in its own batch (go) so the rest keep running.
   ===================================================================== */

/* ---------------- FUNCTION demos ---------------- */

-- cap space for every team in the 2025 league year
-- expected: Giants 279,200,000 / Eagles 215,600,000 / Cowboys 185,200,000
select team_name,
       dbo.f_team_cap_space(team_id, 2025) as cap_space_2025
    from ft_teams
    order by cap_space_2025 desc;
go

-- practical use: which teams can afford a $200M-per-year player right now?
-- expected: Eagles and Giants
select team_name,
       dbo.f_team_cap_space(team_id, 2025) as cap_space_2025
    from ft_teams
    where dbo.f_team_cap_space(team_id, 2025) >= 200000000.00;
go

-- no cap on file for a year -> null
select dbo.f_team_cap_space((select team_id from ft_teams where team_name = 'Eagles'), 2040) as cap_space_2040;
go


/* ---------------- PROCEDURE demos ---------------- */

-- should work: Eagles re-sign Saquon Barkley at $20.6M per year.
-- his old $12.6M is credited back, so Eagles cap space goes 215.6M -> 207.6M.
declare @player int = (select player_id from ft_players where player_first_name = 'Saquon' and player_last_name = 'Barkley');
declare @team int = (select team_id from ft_teams where team_name = 'Eagles');

exec dbo.p_sign_player_contract
    @player_id = @player,
    @team_id = @team,
    @annual_salary = 20600000.00,
    @sign_date = '2025-04-01',
    @expiration_date = '2028-02-28';
go

-- should error (50106): Cowboys try to sign Saquon away for $190M per year.
-- Cowboys only have $185.2M of 2025 cap space.
declare @player int = (select player_id from ft_players where player_first_name = 'Saquon' and player_last_name = 'Barkley');
declare @team int = (select team_id from ft_teams where team_name = 'Cowboys');

exec dbo.p_sign_player_contract
    @player_id = @player,
    @team_id = @team,
    @annual_salary = 190000000.00,
    @sign_date = '2025-05-01',
    @expiration_date = '2027-02-28';
go

-- should error (50105): contract starts in the 2040 league year, no cap on file yet.
declare @player int = (select player_id from ft_players where player_first_name = 'Dak' and player_last_name = 'Prescott');
declare @team int = (select team_id from ft_teams where team_name = 'Cowboys');

exec dbo.p_sign_player_contract
    @player_id = @player,
    @team_id = @team,
    @annual_salary = 45000000.00,
    @sign_date = '2040-03-15',
    @expiration_date = '2042-02-28';
go

-- verify: Saquon is still an Eagle at $20.6M, and the failed signings changed nothing
select p.player_first_name + ' ' + p.player_last_name as player, t.team_name, p.player_salary,
       p.player_contract_sign_date, p.player_contract_expiration_date
    from ft_players p
    join ft_teams t on t.team_id = p.player_team_id
    order by t.team_name, p.player_salary desc;

select team_name, dbo.f_team_cap_space(team_id, 2025) as cap_space_2025
    from ft_teams
    order by cap_space_2025 desc;
go


/* ---------------- TRIGGER demos ---------------- */

-- setup: CeeDee Lamb goes on the injury report (sample injury).
-- injured 2025-09-08, expected back 2025-09-20.
insert into ft_injury_reports (injury_report_player_id, injury_report_injury_date, injury_report_return_date, injury_report_timeline, injury_report_type)
select player_id, '2025-09-08', '2025-09-20', '1-2 weeks', 'Ankle sprain'
    from ft_players
    where player_first_name = 'CeeDee' and player_last_name = 'Lamb'
      and not exists (select 1 from ft_injury_reports r
                      join ft_players p2 on p2.player_id = r.injury_report_player_id
                      where p2.player_first_name = 'CeeDee' and p2.player_last_name = 'Lamb'
                        and r.injury_report_injury_date = '2025-09-08');
go

-- should work: stats from the 2025-09-04 Cowboys @ Eagles game.
-- all three players' teams played, and Lamb wasn't injured yet.
insert into ft_statistics (stat_player_id, stat_game_id, stat_name, stat_total, stat_games_played)
select p.player_id, g.game_id, v.stat_name, v.stat_total, 1
    from (values
        ('Jalen',  'Hurts',   'Passing Yards',   152.00),
        ('Saquon', 'Barkley', 'Rushing Yards',    60.00),
        ('CeeDee', 'Lamb',    'Receiving Yards', 110.00)
    ) as v (first_name, last_name, stat_name, stat_total)
    join ft_players p on p.player_first_name = v.first_name and p.player_last_name = v.last_name
    join ft_games g on g.game_date = '2025-09-04'
    where not exists (select 1 from ft_statistics s
                      where s.stat_player_id = p.player_id and s.stat_game_id = g.game_id and s.stat_name = v.stat_name);
go

-- should error (50111): Jalen Hurts stat in the Giants @ Cowboys game. the Eagles weren't in it.
insert into ft_statistics (stat_player_id, stat_game_id, stat_name, stat_total, stat_games_played)
select p.player_id, g.game_id, 'Passing Yards', 300.00, 1
    from ft_players p
    join ft_games g on g.game_date = '2025-09-14'
    where p.player_first_name = 'Jalen' and p.player_last_name = 'Hurts';
go

-- should error (50112): CeeDee Lamb stat in the 2025-09-14 game. he was on the injury report.
insert into ft_statistics (stat_player_id, stat_game_id, stat_name, stat_total, stat_games_played)
select p.player_id, g.game_id, 'Receiving Yards', 85.00, 1
    from ft_players p
    join ft_games g on g.game_date = '2025-09-14'
    where p.player_first_name = 'CeeDee' and p.player_last_name = 'Lamb';
go

-- should error (50111): one bad row in a multi-row insert rejects the whole insert.
-- Dak's row is valid; Hurts' row is not, so neither is saved.
insert into ft_statistics (stat_player_id, stat_game_id, stat_name, stat_total, stat_games_played)
select p.player_id, g.game_id, v.stat_name, v.stat_total, 1
    from (values
        ('Dak',   'Prescott', 'Passing Yards', 361.00),
        ('Jalen', 'Hurts',    'Rushing Yards',  40.00)
    ) as v (first_name, last_name, stat_name, stat_total)
    join ft_players p on p.player_first_name = v.first_name and p.player_last_name = v.last_name
    join ft_games g on g.game_date = '2025-09-14';
go

-- should error (50111): the trigger also catches updates that move a stat to the wrong game.
update s
    set s.stat_game_id = (select game_id from ft_games where game_date = '2025-09-14')
    from ft_statistics s
    join ft_players p on p.player_id = s.stat_player_id
    where p.player_first_name = 'Jalen' and p.player_last_name = 'Hurts'
      and s.stat_name = 'Passing Yards';
go

-- verify: only the three valid stat lines from 2025-09-04 are saved
select p.player_first_name + ' ' + p.player_last_name as player,
       g.game_date,
       s.stat_name,
       s.stat_total
    from ft_statistics s
    join ft_players p on p.player_id = s.stat_player_id
    join ft_games g on g.game_id = s.stat_game_id
    order by g.game_date, player;
go