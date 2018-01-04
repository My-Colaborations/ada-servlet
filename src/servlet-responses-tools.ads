-----------------------------------------------------------------------
--  servlet-responses.tools -- Servlet Responses Tools
--  Copyright (C) 2011 Stephane Carrez
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

package Servlet.Responses.Tools is

   --  Builds a printable representation of the response for debugging purposes.
   --  When <b>Html</b> is true, the returned content contains an HTML presentation.
   function To_String (Reply            : in Response'Class;
                       Html             : in Boolean := False;
                       Print_Headers    : in Boolean := True) return String;

end Servlet.Responses.Tools;
