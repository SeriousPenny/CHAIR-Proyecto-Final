﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using CHAIRAPI.Utils;
using CHAIRAPI_DAL.Handlers;
using CHAIRAPI_Entities.Complex;
using CHAIRAPI_Entities.Persistent;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace CHAIRAPI.Controllers
{
    [Route("[controller]")]
    [ApiController]
    [Authorize(Roles = "Administrator")]
    public class AdminController : ControllerBase
    {
        /// <summary>
        /// PATCH Method used to ban an user by changing his bannedUntil and banReason
        /// </summary>
        /// <param name="user">The user with the necessary information to ban him: nickname, banReason and bannedUntil</param>
        [HttpPatch("ban")]
        public IActionResult Ban([FromBody]User user)
        {
            if (Utilities.checkUserHasRequiredFieldsToBan(user))
            {
                int updateStatus = UsersHandler.banUser(user);

                if (updateStatus == 1)
                    return StatusCode(204); //No Content
                else if (updateStatus == 0)
                    return StatusCode(404); //Not Found
                else
                    return StatusCode(500); //Internal Server Error
            }
            else
                return StatusCode(400); //Bad Request
            

        }

        /// <summary>
        /// POST Method is used to add new games to the database
        /// </summary>
        /// <param name="game">The game to be added to the database</param>
        [HttpPost("games")]
        public IActionResult AddNewGame([FromBody] Game game)
        {
            string accept = Request.Headers["Content-Type"].ToString();
            if (accept != "application/json" && accept != "*/*")
                return StatusCode(415);
            else
            {
                //Save to the database and collect status message (specified in the handler)
                int saveStatus = GamesHandler.saveNewGame(game);

                //Return the status code depending on what happened when saving the user
                if (saveStatus == 1)
                    return StatusCode(201); //Created
                else if (saveStatus == 0)
                    return StatusCode(409); //Conflict
                else
                    return StatusCode(500); //Internal Server Error
            }
        }

        /// <summary>
        /// PUT Method is used to update a game
        /// </summary>
        /// <param name="game">The game to update</param>
        [HttpPut("games")]
        public IActionResult Put([FromBody] Game game)
        {
            int updateStatus = GamesHandler.updateGame(game);

            if (updateStatus == 1)
                return StatusCode(204); //No Content
            else if (updateStatus == 0)
                return StatusCode(404); //Not Found
            else
                return StatusCode(500); //Internal Server Error
        }

        /// <summary>
        /// GET Method used to get all the users in the platform (doesn't include admins)
        /// </summary>
        [HttpGet("users")]
        public IActionResult GetAllUsers()
        {
            List<string> users = AdminHandler.getAllUsers();
            
            if (users != null)
                return Ok(users); //Not Found
            else
                return StatusCode(500); //Internal Server Error
        }

        /// <summary>
        /// GET Method used to get all the banned users in the platform
        /// </summary>
        [HttpGet("bannedusers")]
        public IActionResult GetAllBannedUsers()
        {
            List<string> users = AdminHandler.getAllBannedUsers();
            
            if (users != null)
                return Ok(users); //Not Found
            else
                return StatusCode(500); //Internal Server Error
        }

        /// <summary>
        /// PATCH Method used to get all the banned IPs in the platform
        /// </summary>
        /// <param name="user">The user with the necessary information to ban him: nickname, banReason and bannedUntil</param>
        [HttpPatch("banuserandip")]
        public IActionResult BanUserAndIp([FromBody]User user)
        {
            int status = AdminHandler.banUserAndIp(user);

            if (status == 1)
                return StatusCode(204); //No Content
            else
                return StatusCode(500); //Internal Server Error
        }

        /// <summary>
        /// PATCH Method used to pardon an user from his ban
        /// </summary>
        /// <param name="user">The nickname of the user to be pardoned</param>
        [HttpPatch("pardonuser/{user}")]
        public IActionResult PardonUser(string user)
        {
            int status = AdminHandler.pardonUser(user);

            if (status == 1)
                return StatusCode(204); //No Content
            else if (status == 0)
                return StatusCode(404); //Not Found
            else
                return StatusCode(500); //Internal Server Error
        }

        /// <summary>
        /// PATCH Method used to pardon an user and his IP from their ban
        /// </summary>
        /// <param name="user">The nickname of the user to be pardoned</param>
        [HttpPatch("pardonuserandip/{user}")]
        public IActionResult PardonUserAndIP(string user)
        {
            int status = AdminHandler.pardonUserAndIP(user);

            if (status == 1)
                return StatusCode(204); //No Content
            else if (status == 0)
                return StatusCode(404); //Not Found
            else
                return StatusCode(500); //Internal Server Error
        }

        /// <summary>
        /// GET Method to get all games in the database with how many users play each game, how many users are playing it, and for how many hours have all users
        /// played that game
        /// </summary>
        [HttpGet("gamesstats")]
        public IActionResult GetAllGamesStats()
        {
            string accept = Request.Headers["Accept"].ToString();
            if (accept != "application/json" && accept != "*/*")
                return StatusCode(406); //Not Acceptable
            else
            {
                List<GameBeingPlayed> games = AdminHandler.getGamesBeingPlayed();

                if (games != null)
                    return Ok(games);
                else
                    return StatusCode(500);
            }
        }

        /// <summary>
        /// PUT Method is used to update a game and set its frontpage status to true
        /// </summary>
        /// <param name="game">The name of the game to be set to front page</param>
        [HttpPatch("frontpage/{game}")]
        public IActionResult ChangeFrontPageGame(string game)
        {
            int updateStatus = AdminHandler.updateFrontPageGame(game);

            if (updateStatus >= 1)
                return StatusCode(204); //No Content
            else if (updateStatus == 0)
                return StatusCode(404); //Not Found
            else
                return StatusCode(500); //Internal Server Error
        }
    }
}