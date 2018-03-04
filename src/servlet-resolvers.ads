-----------------------------------------------------------------------
--  servlet-resolvers -- Resolver to create and give access to managed beans
--  Copyright (C) 2013, 2015, 2018 Stephane Carrez
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
with Ada.Finalization;
with Ada.Strings.Unbounded;

with Util.Beans.Basic;
with Util.Beans.Objects;
with EL.Contexts;

with Servlet.Core;
with Servlet.Requests;
package Servlet.Resolvers is

   --  ------------------------------
   --  Bean Resolver
   --  ------------------------------
   type ELResolver is limited new EL.Contexts.ELResolver with private;

   --  Initialize the EL resolver to use the application bean factory and the given request.
   procedure Initialize (Resolver : in out ELResolver;
                         App      : in Servlet.Core.Servlet_Registry_Access;
                         Request  : in Servlet.Requests.Request_Access);

   --  Resolve the name represented by <tt>Name</tt> according to a base object <tt>Base</tt>.
   --  The resolver tries to look first in pre-defined objects (params, flash, headers, initParam).
   --  It then looks in the request and session attributes for the value.  If the value was
   --  not in the request or session, it uses the application bean factory to create the
   --  new managed bean and adds it to the request or session.
   overriding
   function Get_Value (Resolver : in ELResolver;
                       Context  : in EL.Contexts.ELContext'Class;
                       Base     : access Util.Beans.Basic.Readonly_Bean'Class;
                       Name     : in Ada.Strings.Unbounded.Unbounded_String)
                       return Util.Beans.Objects.Object;

   --  Sets the value represented by the <tt>Name</tt> in the base object <tt>Base</tt>.
   --  If there is no <tt>Base</tt> object, the request attribute with the given name is
   --  updated to the given value.
   overriding
   procedure Set_Value (Resolver : in out ELResolver;
                        Context  : in EL.Contexts.ELContext'Class;
                        Base     : access Util.Beans.Basic.Bean'Class;
                        Name     : in Ada.Strings.Unbounded.Unbounded_String;
                        Value    : in Util.Beans.Objects.Object);

private

   type ELResolver is limited new Ada.Finalization.Limited_Controlled
     and EL.Contexts.ELResolver with record
      --  The current request.
      Request           : Servlet.Requests.Request_Access;

      --  The current servlet registry.
      Application       : Servlet.Core.Servlet_Registry_Access;
   end record;

end Servlet.Resolvers;
