﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using CHAIRAPI.Responses;
using CHAIRAPI.Utils;
using CHAIRAPI_DAL.Handlers;
using CHAIRAPI_Entities.Persistent;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace CHAIRAPI.Controllers
{
    [Route("[controller]")]
    [ApiController]
    [Authorize]
    public class UsersController : ControllerBase
    {
        /// <summary>
        /// POST Method from UsersControllers is used to register new users
        /// </summary>
        /// <param name="user">The user that will be stored in the database</param>
        [HttpPost("register")]
        [AllowAnonymous]
        public IActionResult Register([FromBody] User user)
        {
            string accept = Request.Headers["Content-Type"].ToString();
            if (accept != "application/json" && accept != "*/*")
                return StatusCode(415);
            else if (Utilities.checkUserHasRequiredFieldsToRegister(user))
            {
                //If the user isn't banned, it will return null
                BanResponse banResponse = Utilities.isUserBanned(user);

                if (banResponse == null)
                {
                    //Create the salt and hashed password
                    string salt = Hash.CreateSalt();
                    string hashedPassword = Hash.Create(user.password, salt);
                    user.password = hashedPassword;

                    //This is the user that will be sent to the DAL and will be stored
                    UserWithSalt dbUser = new UserWithSalt(user, salt);

                    //Save to the database and collect status message (specified in the handler)
                    int saveStatus = UsersHandler.saveNewUser(dbUser);

                    //Return the status code depending on what happened when saving the user
                    if (saveStatus == 1)
                        return StatusCode(201); //Created
                    else if (saveStatus == 0)
                        return StatusCode(409); //Conflict
                    else
                        return StatusCode(500); //Internal Server Error
                }
                else
                    return StatusCode(401, banResponse); //Unauthorized by ban
            }
            else
                return StatusCode(400); //Bad Request
        }

        /// <summary>
        /// POST Method used to login
        /// </summary>
        /// <param name="user">The user with the necessary information to login: nickname, password and lastIP</param>
        [HttpPost("login")]
        [AllowAnonymous]
        public IActionResult Login([FromBody] User user)
        {
            string accept = Request.Headers["Accept"].ToString();
            if (accept != "application/json" && accept != "*/*")
                return StatusCode(406); //Not Acceptable
            else if(Utilities.checkUserHasRequiredFieldsToLogin(user)) //If it has username, password and IP
            {
                UserWithSalt userWithSalt = UsersHandler.searchUserByNickname(user.nickname);

                if (userWithSalt != null && Hash.Validate(user.password, userWithSalt.salt, userWithSalt.password)) //If the passwords coincide
                {
                    //Update the lastIP from the user
                    UsersHandler.updateUserIP(user.nickname, user.lastIP);
                    userWithSalt.lastIP = user.lastIP;
                    BanResponse banResponse = Utilities.isUserBanned(userWithSalt);

                    //If the user isn't banned, banResponse should be null
                    if (banResponse == null)
                    {
                        Response.Headers.Add("Authentication", "Bearer " + Utilities.generateToken(userWithSalt));
                        return Ok(Utilities.convertUserWithSaltToUser(userWithSalt)); //Send an user instance without salt nor the password in it
                    }
                    else
                        return StatusCode(401, banResponse); //Unauthorized by ban
                }
                else
                    return StatusCode(401); //Unauthorized
            }
            else
                return StatusCode(400); //Bad Request
        }

        /// <summary>
        /// PUT Method from UsersController is used to update the information of the user
        /// </summary>
        /// <param name="user">The user with the updated information</param>
        /// <param name="nickname">The user's nickname</param>
        [HttpPut]
        public IActionResult UpdateUser([FromBody] User user)
        {
            if (Utilities.checkUserHasRequiredFieldsToUpdate(user))
            {
                if (Utilities.checkUsrClaimValidity(User, user.nickname))
                {
                    UserWithSalt userWS = Utilities.convertUserToUserWithSalt(user);
                    //Since we're updating, we're going to create another salt and hashed password for the user
                    //just in case he has decided to update his password
                    if(!string.IsNullOrWhiteSpace(user.password))
                    {
                        userWS.salt = Hash.CreateSalt();
                        userWS.password = Hash.Create(userWS.password, userWS.salt);
                    }

                    int updateStatus = UsersHandler.updateUser(userWS);

                    if (updateStatus == 1)
                    {
                        //Generate another token, because if the user changes his nickname, the old one will be rendered obsolete
                        Response.Headers.Add("Authentication", "Bearer " + Utilities.generateToken(userWS));
                        return StatusCode(204); //No Content
                    }
                    else if (updateStatus == 0)
                        return StatusCode(404); //Not Found
                    else if (updateStatus == -1)
                        return StatusCode(409); //Conflict
                    else
                        return StatusCode(500); //Internal Server Error
                }
                else
                    return StatusCode(401); //Unauthorized
            }
            else
                return StatusCode(400); //Bad Request

        }

        /// <summary>
        /// PATCH Method used to set the user's online status to true
        /// </summary>
        /// <param name="nickname">The user's nickname</param>
        [HttpPatch("{nickname}/online")]
        public IActionResult Online(string nickname)
        {
            if (Utilities.checkUsrClaimValidity(User, nickname))
            {
                int updateStatus = UsersHandler.updateUserStatus(nickname, true);
                if (updateStatus == 1)
                    return StatusCode(204); //No Content
                else if (updateStatus == 0)
                    return StatusCode(404); //Not Found
                else
                    return StatusCode(500); //Internal Server Error
            }
            else
                return StatusCode(401); //Unauthorized

        }

        /// <summary>
        /// PATCH Method used to set the user's online status to false
        /// </summary>
        /// <param name="nickname">The user's nickname</param>
        [HttpPatch("{nickname}/offline")]
        public IActionResult Offline(string nickname)
        {
            if (Utilities.checkUsrClaimValidity(User, nickname))
            {
                int updateStatus = UsersHandler.updateUserStatus(nickname, false);
                if (updateStatus == 1)
                    return StatusCode(204); //No Content
                else if (updateStatus == 0)
                    return StatusCode(404); //Not Found
                else
                    return StatusCode(500); //Internal Server Error
            }
            else
                return StatusCode(401); //Unauthorized

        }
    }
}