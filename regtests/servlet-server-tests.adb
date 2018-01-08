-----------------------------------------------------------------------
--  servlet-server-tests - Unit tests for server requests
--  Copyright (C) 2018 Stephane Carrez
--  Written by Stephane Carrez (Stephane.Carrez@gmail.com)
--
--  Licensed under the Apache License, Version 2.0 (the "License");
--  you may not use this file except in compliance with the License.
--  You may obtain a copy of the License at
--
--      http://www.apache.org/licenses/LICENSE-2.0
--
--  Unless required by applicable law or agreed to in writing, software
--  distributed under the License is distributed on an "AS IS" BASIS,
--  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--  See the License for the specific language governing permissions and
--  limitations under the License.
-----------------------------------------------------------------------

with Ada.Strings.Unbounded;

with Util.Tests;
with Util.Beans.Objects;
with Util.Test_Caller;
with Servlet.Tests;
with Servlet.Requests.Mockup;
with Servlet.Responses.Mockup;

package body Servlet.Server.Tests is

   use Servlet.Tests;
   use Util.Tests;

   package Caller is new Util.Test_Caller (Test, "Cookies");

   procedure Add_Tests (Suite : in Util.Tests.Access_Test_Suite) is
   begin
      Caller.Add_Test (Suite, "Test Servlet.Server.Service",
                       Test_Service'Access);
      Caller.Add_Test (Suite, "Test Servlet.Server.Service (GET)",
                       Test_Get_File'Access);
      Caller.Add_Test (Suite, "Test Servlet.Server.Service (GET 404",
                       Test_Get_404'Access);
    end Add_Tests;

   --  Initialize the test.
   overriding
   procedure Set_Up (T : in out Test) is
      use type Servlet.Servlets.Servlet_Registry_Access;
   begin
      if Servlet.Tests.Get_Application = null then
         Servlet.Tests.Initialize (Util.Tests.Get_Properties);
      end if;
      Servlet.Tests.Get_Application.Start;
   end Set_Up;

   --  ------------------------------
   --  Test the Service procedure.
   --  ------------------------------
   procedure Test_Service (T : in out Test) is
      Request : Servlet.Requests.Mockup.Request;
      Reply   : Servlet.Responses.Mockup.Response;
   begin
      Request.Set_Method (Method => "GET");
      Request.Set_Request_URI (URI => "tst", Split => True);
      Request.Set_Protocol (Protocol => "HTTP/1.1");
      Servlet.Tests.Get_Server.Service (Request, Reply);
      Assert_Equals (T, Servlet.Responses.SC_NOT_FOUND, Reply.Get_Status, "Invalid response");
      Assert_Matches (T, ".*servlet.error.status_code.*404.*", Reply, "Invalid 404 page returned",
                      Status => Servlet.Responses.SC_NOT_FOUND);
   end Test_Service;

   --  ------------------------------
   --  Test a GET request on a static file served by the File_Servlet.
   --  ------------------------------
   procedure Test_Get_404 (T : in out Test) is
      Request : Servlet.Requests.Mockup.Request;
      Reply   : Servlet.Responses.Mockup.Response;
   begin
      Do_Get (Request, Reply, "/file-does-not-exist.txt", "test-404.html");
      Assert_Equals (T, Servlet.Responses.SC_NOT_FOUND, Reply.Get_Status, "Invalid response");
      Assert_Matches (T, ".*servlet.error.status_code.*404.*", Reply, "Invalid 404 page returned",
                      Status => Servlet.Responses.SC_NOT_FOUND);

      Do_Get (Request, Reply, "/file-does-not-exist.js", "test-404.html");
      Assert_Equals (T, Servlet.Responses.SC_NOT_FOUND, Reply.Get_Status, "Invalid response");
      Assert_Matches (T, ".*servlet.error.status_code.*404.*", Reply, "Invalid 404 page returned",
                      Status => Servlet.Responses.SC_NOT_FOUND);
   end Test_Get_404;

   --  ------------------------------
   --  Test a GET request on a static file served by the File_Servlet.
   --  ------------------------------
   procedure Test_Get_File (T : in out Test) is
      Request : Servlet.Requests.Mockup.Request;
      Reply   : Servlet.Responses.Mockup.Response;
   begin
      Do_Get (Request, Reply, "/tests/file.txt", "get-file.txt");
      Assert_Contains (T, "A plain text file.", Reply, "Wrong content");
      Assert_Header (T, "Content-Type", "text/plain", Reply, "Content-Type");

      Do_Get (Request, Reply, "/tests/file.html", "get-file-set.html");
      Assert_Matches (T, "<html></html>", Reply, "Wrong content");
      Assert_Header (T, "Content-Type", "text/html", Reply, "Content-Type");

      Do_Get (Request, Reply, "/tests/file.js", "get-file.js");
      Assert_Matches (T, "^\s*var n = 0;.*", Reply, "Wrong content");
      Assert_Header (T, "Content-Type", "text/javascript", Reply, "Content-Type");

      Do_Get (Request, Reply, "/tests/file.css", "get-file.css");
      Assert_Matches (T, "^\s*div { margin: 0 }.*", Reply, "Wrong content");
      Assert_Header (T, "Content-Type", "text/css", Reply, "Content-Type");

   end Test_Get_File;

   --  ------------------------------
   --  Test a GET request on the measure servlet
   --  ------------------------------
   procedure Test_Get_Measures (T : in out Test) is
      Request : Servlet.Requests.Mockup.Request;
      Reply   : Servlet.Responses.Mockup.Response;
   begin
      Do_Get (Request, Reply, "/stats.xml", "stats.xml");

      --  We must get at least one measure value (assuming the Test_Get_File test
      --  was executed).
      Assert_Matches (T, "<time count=""\d+"" time=""\d+.\d+ [um]s"" title="".*""/>",
                      Reply, "Wrong content");
   end Test_Get_Measures;

end Servlet.Server.Tests;
