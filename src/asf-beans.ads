-----------------------------------------------------------------------
--  asf.beans -- Bean Registration and Factory
--  Copyright (C) 2009, 2010, 2011 Stephane Carrez
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

with Ada.Strings.Hash;
with Ada.Strings.Unbounded;

with Util.Beans.Basic;

with Ada.Containers.Hashed_Maps;
with Ada.Containers.Indefinite_Hashed_Maps;
private with Ada.Strings.Unbounded.Hash;

--  The <b>ASF.Beans</b> package is a registry for creating request, session
--  and application beans.
--
--  First, an application or a module registers in a class factory the class
--  of objects that can be created.  Each class is represented by a <b>Class_Binding</b>
--  interface that allows to create instances of the given class.  Each class
--  is associated with a unique name in the class factory (ie, the class name).
--  This step is done when the application or module is initialized.
--
--  Second, a set of application configuration files define the runtime bean objects
--  that can be created automatically when a request is processed.  Each runtime bean
--  object is associated with a bean name, a bean type identifying the class of object,
--  and a scope that identifies the lifespan of the object.
--
--  When a request is processed and a bean must be created, the bean factory is
--  searched to find a the object class and object scope (a <b>Bean_Binding</b>).
--  The <b>Class_Binding</b> associated with the <b>Bean_Binding</b> is then used
--  to create the object.
package ASF.Beans is

   --  Defines the scope of the bean instance.
   type Scope_Type is
     (
      --  Application scope means the bean is shared by all sessions and requests
      APPLICATION_SCOPE,

      --  Session scope means the bean is created one for each session.
      SESSION_SCOPE,

      --  Request scope means the bean is created for each request
      REQUEST_SCOPE,

      ANY_SCOPE);

   --  ------------------------------
   --  Class Binding
   --  ------------------------------
   --  The <b>Class_Binding</b> provides an operation to create objects of a given class.
   type Class_Binding is interface;
   type Class_Binding_Access is access all Class_Binding'Class;

   procedure Create (Factory : in Class_Binding;
                     Name    : in Ada.Strings.Unbounded.Unbounded_String;
                     Result  : out Util.Beans.Basic.Readonly_Bean_Access) is abstract;

   --  ------------------------------
   --  Bean Factory
   --  ------------------------------
   --  The registry maintains a list of creation bindings which allow to create
   --  a bean object of a particular type.
   type Bean_Factory is limited private;

   --  Register under the name identified by <b>Name</b> the class instance <b>Class</b>.
   procedure Register_Class (Factory : in out Bean_Factory;
                             Name    : in String;
                             Class   : in Class_Binding_Access);

   --  Register all the definitions from a factory to a main factory.
   procedure Register (Factory : in out Bean_Factory;
                       From    : in Bean_Factory);

   --  Register the bean identified by <b>Name</b> and associated with the class <b>Class</b>.
   --  The class must have been registered by using the <b>Register</b> class operation.
   --  The scope defines the scope of the bean.
   procedure Register (Factory : in out Bean_Factory;
                       Name    : in String;
                       Class   : in String;
                       Scope   : in Scope_Type := REQUEST_SCOPE);

   --  Register the bean identified by <b>Name</b> and associated with the class <b>Class</b>.
   --  The class must have been registered by using the <b>Register</b> class operation.
   --  The scope defines the scope of the bean.
   procedure Register (Factory : in out Bean_Factory;
                       Name    : in String;
                       Class   : in Class_Binding_Access;
                       Scope   : in Scope_Type := REQUEST_SCOPE);

   --  Create a bean by using the create operation registered for the name
   procedure Create (Factory : in Bean_Factory;
                     Name    : in Ada.Strings.Unbounded.Unbounded_String;
                     Result  : out Util.Beans.Basic.Readonly_Bean_Access;
                     Scope   : out Scope_Type);

private

   use Ada.Strings.Unbounded;

   package Registry_Maps is new
     Ada.Containers.Indefinite_Hashed_Maps (Key_Type     => String,
                                            Element_Type => Class_Binding_Access,
                                            Hash         => Ada.Strings.Hash,
                                            Equivalent_Keys => "=");

   type Bean_Binding is record
      Scope  : Scope_Type;
      Create : Class_Binding_Access;
   end record;

   package Bean_Maps is new
     Ada.Containers.Hashed_Maps (Key_Type     => Unbounded_String,
                                 Element_Type => Bean_Binding,
                                 Hash         => Ada.Strings.Unbounded.Hash,
                                 Equivalent_Keys => "=");

   type Bean_Factory is limited record
      Registry : Registry_Maps.Map;
      Map      : Bean_Maps.Map;
   end record;

end ASF.Beans;
