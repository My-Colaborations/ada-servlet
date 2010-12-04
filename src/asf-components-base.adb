-----------------------------------------------------------------------
--  components -- Component tree
--  Copyright (C) 2009, 2010 Stephane Carrez
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

with Util.Log.Loggers;
with Ada.Unchecked_Deallocation;
with ASF.Views.Nodes;
with ASF.Converters;
with ASF.Events;
package body ASF.Components.Base is

   use Util.Log;

   --  The logger
   Log : constant Loggers.Logger := Loggers.Create ("ASF.Components.Base");

   --  ------------------------------
   --  Get the parent component.
   --  Returns null if the node is the root element.
   --  ------------------------------
   function Get_Parent (UI : UIComponent) return UIComponent_Access is
   begin
      return UI.Parent;
   end Get_Parent;

   --  ------------------------------
   --  Return a client-side identifier for this component, generating
   --  one if necessary.
   --  ------------------------------
   function Get_Client_Id (UI : UIComponent) return Unbounded_String is
   begin
      return UI.Id;
   end Get_Client_Id;

   --  ------------------------------
   --  Get the list of children.
   --  ------------------------------
   function Get_Children (UI : UIComponent) return UIComponent_List is
      Result : UIComponent_List;
   begin
      Result.Child := UI.First_Child;
      return Result;
   end Get_Children;

   --  ------------------------------
   --  Get the number of children.
   --  ------------------------------
   function Get_Children_Count (UI : UIComponent) return Natural is
      Result : Natural := 0;
      Child  : UIComponent_Access := UI.First_Child;
   begin
      while Child /= null loop
         Result := Result + 1;
         Child := Child.Next;
      end loop;
      return Result;
   end Get_Children_Count;

   --  ------------------------------
   --  Get the first child component.
   --  Returns null if the component has no children.
   --  ------------------------------
   function Get_First_Child (UI : UIComponent) return UIComponent_Access is
   begin
      return UI.First_Child;
   end Get_First_Child;

   --  ------------------------------
   --  Get the tag node that created this component.
   --  ------------------------------
   function Get_Tag (UI : in UIComponent'Class) return access ASF.Views.Nodes.Tag_Node'Class is
   begin
      return UI.Tag;
   end Get_Tag;

   --  ------------------------------
   --  Initialize the component when restoring the view.
   --  The default initialization gets the client ID and allocates it if necessary.
   --  ------------------------------
   procedure Initialize (UI      : in out UIComponent;
                         Context : in out Faces_Context'Class) is
      --  Then, look in the static attributes
      Attr : constant access ASF.Views.Nodes.Tag_Attribute := UI.Get_Attribute ("id");
   begin
      if Attr = null then
         UI.Id := To_Unbounded_String ("d");
      else
         UI.Id := EL.Objects.To_Unbounded_String (ASF.Views.Nodes.Get_Value (Attr.all, UI));
      end if;
   end Initialize;

   procedure Append (UI    : in UIComponent_Access;
                     Child : in UIComponent_Access;
                     Tag   : access ASF.Views.Nodes.Tag_Node'Class) is
   begin
      Child.Tag    := Tag;
      Child.Parent := UI;
      Child.Next   := null;
      if UI.Last_Child = null then
         UI.First_Child := Child;
      else
         UI.Last_Child.Next := Child;
      end if;
      UI.Last_Child := Child;
   end Append;

   --  ------------------------------
   --  Search for and return the {@link UIComponent} with an <code>id</code>
   --  that matches the specified search expression (if any), according to
   --  the algorithm described below.
   --  ------------------------------
   function Find (UI : UIComponent;
                  Name : String) return UIComponent_Access is
   begin
      return null;
   end Find;

   function Get_Context (UI : in UIComponent)
                         return ASF.Contexts.Faces.Faces_Context_Access is
      pragma Unreferenced (UI);
   begin
      return ASF.Contexts.Faces.Current;
   end Get_Context;

   --  ------------------------------
   --  Check whether the component and its children must be rendered.
   --  ------------------------------
   function Is_Rendered (UI : UIComponent;
                         Context : Faces_Context'Class) return Boolean is
      Attr : constant EL.Objects.Object := UI.Get_Attribute (Context, "rendered");
   begin
      if EL.Objects.Is_Null (Attr) then
         return True;
      end if;
      return EL.Objects.To_Boolean (Attr);
   end Is_Rendered;

   --  ------------------------------
   --  Set whether the component is rendered.
   --  ------------------------------
   procedure Set_Rendered (UI       : in out UIComponent;
                           Rendered : in Boolean) is
   begin
      null;
   end Set_Rendered;


   function Get_Attribute (UI      : UIComponent;
                           Context : Faces_Context'Class;
                           Name    : String) return EL.Objects.Object is
      Attribute : UIAttribute_Access := UI.Attributes;
   begin
      --  Look first in the dynamic attribute list (owned by this UIComponent)
      while Attribute /= null loop
         declare
            Attr_Name : constant String := ASF.Views.Nodes.Get_Name (Attribute.Definition.all);
         begin
            if Attr_Name = Name then
               --  The attribute value can be a constant or an expression.
               if not EL.Objects.Is_Null (Attribute.Value) then
                  return Attribute.Value;
               else
                  return Attribute.Expr.Get_Value (Context.Get_ELContext.all);
               end if;
            end if;
         end;
         Attribute := Attribute.Next_Attr;
      end loop;

      --  Then, look in the static attributes
      declare
         Attr : constant access ASF.Views.Nodes.Tag_Attribute := UI.Get_Attribute (Name);
      begin
         if Attr = null then
            return EL.Objects.Null_Object;
         end if;
         return ASF.Views.Nodes.Get_Value (Attr.all, UI);
      end;
   end Get_Attribute;

   --  ------------------------------
   --  Get the attribute tag
   --  ------------------------------
   function Get_Attribute (UI      : UIComponent;
                           Name    : String)
                           return access ASF.Views.Nodes.Tag_Attribute is
   begin
      if UI.Tag = null then
         return null;
      else
         return UI.Tag.Get_Attribute (Name);
      end if;
   end Get_Attribute;

   procedure Set_Attribute (UI    : in out UIComponent;
                            Name  : in String;
                            Value : in EL.Objects.Object) is
   begin
      null;
   end Set_Attribute;

   procedure Set_Attribute (UI    : in out UIComponent;
                            Def   : access ASF.Views.Nodes.Tag_Attribute;
                            Value : in EL.Expressions.Expression) is
      Attribute : UIAttribute_Access := UI.Attributes;
      Name      : constant String := ASF.Views.Nodes.Get_Name (Def.all);
   begin
      while Attribute /= null loop
         declare
            Attr_Name : constant String := ASF.Views.Nodes.Get_Name (Attribute.Definition.all);
         begin
            if Attr_Name = Name then
               Attribute.Expr := Value;
               Attribute.Value := EL.Objects.Null_Object;
               return;
            end if;
         end;
         Attribute := Attribute.Next_Attr;
      end loop;
      Attribute := new UIAttribute;
      Attribute.Definition := Def;
      Attribute.Value := EL.Objects.Null_Object;
      Attribute.Expr  := Value;
      Attribute.Next_Attr := UI.Attributes;
      UI.Attributes := Attribute;
   end Set_Attribute;

   procedure Set_Attribute (UI    : in out UIComponent;
                            Def   : access ASF.Views.Nodes.Tag_Attribute;
                            Value : in EL.Objects.Object) is
      Attribute : UIAttribute_Access := UI.Attributes;
      Name      : constant String := ASF.Views.Nodes.Get_Name (Def.all);
   begin
      while Attribute /= null loop
         declare
            Attr_Name : constant String := ASF.Views.Nodes.Get_Name (Attribute.Definition.all);
         begin
            if Attr_Name = Name then
               Attribute.Value := Value;
               return;
            end if;
         end;
         Attribute := Attribute.Next_Attr;
      end loop;
      Attribute := new UIAttribute;
      Attribute.Definition := Def;
      Attribute.Value := Value;
      Attribute.Next_Attr := UI.Attributes;
      UI.Attributes := Attribute;
   end Set_Attribute;

   --  Get the value expression
   function Get_Value_Expression (UI   : in UIComponent;
                                  Name : in String) return EL.Expressions.Value_Expression is
      Value : constant access ASF.Views.Nodes.Tag_Attribute := UI.Get_Attribute (Name);
   begin
      if Value = null then
         raise EL.Expressions.Invalid_Expression with "No value expression for: " & Name;
      end if;

      return ASF.Views.Nodes.Get_Value_Expression (Value.all);
   end Get_Value_Expression;

   --  ------------------------------
   --  Get the converter associated with the component
   --  ------------------------------
   function Get_Converter (UI      : in UIComponent;
                           Context : in Faces_Context'Class)
                           return access ASF.Converters.Converter'Class is
      Name : constant EL.Objects.Object
        := UIComponent'Class (UI).Get_Attribute (Name    => "converter",
                                                 Context => Context);
   begin
      return Context.Get_Converter (Name);
   end Get_Converter;

   --  ------------------------------
   --  Convert the string into a value.  If a converter is specified on the component,
   --  use it to convert the value.
   --  ------------------------------
   function Convert_Value (UI      : in UIComponent;
                           Value   : in String;
                           Context : in Faces_Context'Class) return EL.Objects.Object is
      Convert : constant access ASF.Converters.Converter'Class
        := UIComponent'Class (UI).Get_Converter (Context);
   begin
      if Convert = null then
         return EL.Objects.To_Object (Value);
      else
         return Convert.To_Object (Context   => Context,
                                   Component => UI,
                                   Value     => Value);
      end if;
   end Convert_Value;

   procedure Encode_Begin (UI      : in UIComponent;
                           Context : in out Faces_Context'Class) is
   begin
      null;
   end Encode_Begin;

   procedure Encode_Children (UI      : in UIComponent;
                              Context : in out Faces_Context'Class) is
      Child : UIComponent_Access;
   begin
      --  Do not render the children if the component is not rendered.
      if not UI.Is_Rendered (Context) then
         return;
      end if;

      Child := UI.First_Child;
      while Child /= null loop
         Child.Encode_All (Context);
         Child := Child.Next;
      end loop;
   end Encode_Children;

   procedure Encode_End (UI      : in UIComponent;
                         Context : in out Faces_Context'Class) is
   begin
      null;
   end Encode_End;

   procedure Encode_All (UI      : in UIComponent'Class;
                         Context : in out Faces_Context'Class) is
   begin
      UI.Encode_Begin (Context);
      UI.Encode_Children (Context);
      UI.Encode_End (Context);
   end Encode_All;

   procedure Decode (UI      : in out UIComponent;
                     Context : in out Faces_Context'Class) is
   begin
      null;
   end Decode;

   procedure Decode_Children (UI      : in UIComponent'Class;
                              Context : in out Faces_Context'Class) is
      Child : UIComponent_Access;
   begin
      Child := UI.First_Child;
      while Child /= null loop
         Child.Process_Decodes (Context);
         Child := Child.Next;
      end loop;
   end Decode_Children;

   procedure Process_Decodes (UI      : in out UIComponent;
                              Context : in out Faces_Context'Class) is
   begin
      --  Do not decode the component nor its children if the component is not rendered.
      if not UI.Is_Rendered (Context) then
         return;
      end if;

      UI.Decode_Children (Context);
      UIComponent'Class (UI).Decode (Context);
   end Process_Decodes;

   --  ------------------------------
   --  Perform the component tree processing required by the <b>Process Validations</b>
   --  phase of the request processing lifecycle for all facets of this component,
   --  all children of this component, and this component itself, as follows:
   --  <ul>
   --    <li>If this component <b>rendered</b> property is false, skip further processing.
   --    <li>Call the <b>Process_Validators</b> of all facets and children.
   --  <ul>
   --  ------------------------------
   procedure Process_Validators (UI      : in out UIComponent;
                                 Context : in out Faces_Context'Class) is
      Child : UIComponent_Access;
   begin
      --  Do not process validation of the component nor its children
      --  if this component is not rendered.
      if not UI.Is_Rendered (Context) then
         return;
      end if;
      Child := UI.First_Child;
      while Child /= null loop
         Child.Process_Validators (Context);
         Child := Child.Next;
      end loop;
   end Process_Validators;

   procedure Process_Updates (UI      : in out UIComponent;
                              Context : in out Faces_Context'Class) is
      Child : UIComponent_Access;
   begin
      --  Do not decode the component nor its children if the component is not rendered.
      if not UI.Is_Rendered (Context) then
         return;
      end if;
      Child := UI.First_Child;
      while Child /= null loop
         Child.Process_Updates (Context);
         Child := Child.Next;
      end loop;
   end Process_Updates;

   --  ------------------------------
   --  Queue an event for broadcast at the end of the current request
   --  processing lifecycle phase.  The default implementation in
   --  delegates this call to the parent component.  The <b>UIViewRoot</b>
   --  component is in charge of queueing events.  The event object
   --  will be freed after being dispatched.
   --  ------------------------------
   procedure Queue_Event (UI    : in out UIComponent;
                          Event : not null access ASF.Events.Faces_Event'Class) is
   begin
      UI.Parent.Queue_Event (Event);
   end Queue_Event;

   --  ------------------------------
   --  Broadcast the event to the event listeners installed on this component.
   --  Listeners are called in the order in which they were added.
   --  ------------------------------
   procedure Broadcast (UI      : in out UIComponent;
                        Event   : not null access ASF.Events.Faces_Event'Class;
                        Context : in out Faces_Context'Class) is
   begin
      LOG.Error ("Event dispatched to a component that cannot handle it");
   end Broadcast;

   --  ------------------------------
   --  Iterate over the children of the component and execute
   --  the <b>Process</b> procedure.
   --  ------------------------------
   procedure Iterate (UI : in UIComponent'Class) is
      Child : UIComponent_Access := UI.First_Child;
   begin
      while Child /= null loop
         Process (Child);
         Child := Child.Next;
      end loop;
   end Iterate;

   --  ------------------------------
   --  Iterate over the attributes defined on the component and
   --  execute the <b>Process</b> procedure.
   --  ------------------------------
   procedure Iterate_Attributes (UI : in UIComponent'Class) is
      Attribute : UIAttribute_Access := UI.Attributes;

      procedure Process_Tag_Attribute (Attr : in ASF.Views.Nodes.Tag_Attribute_Access) is
         A : UIAttribute;
      begin
         A.Definition := Attr;
         Process (ASF.Views.Nodes.Get_Name (Attr.all), A);
      end Process_Tag_Attribute;

      procedure Iterate_Tag_Attributes is new
        ASF.Views.Nodes.Iterate_Attributes (Process_Tag_Attribute);

   begin
      --  Iterate first over the component modified attributes.
      while Attribute /= null loop
         Process (ASF.Views.Nodes.Get_Name (Attribute.Definition.all), Attribute.all);
         Attribute := Attribute.Next_Attr;
      end loop;

      Iterate_Tag_Attributes (UI.Tag.all);
   end Iterate_Attributes;

   --  ------------------------------
   --  Get the attribute value.
   --  ------------------------------
   function Get_Value (Attr : UIAttribute;
                       UI   : UIComponent'Class) return EL.Objects.Object is
   begin
      if not EL.Objects.Is_Null (Attr.Value) then
         return Attr.Value;
      else
         return ASF.Views.Nodes.Get_Value (Attr.Definition.all, UI);
      end if;
   end Get_Value;

   --  Get the root component from the <b>UI</b> component tree.
   --  After the operation, the <b>UI</b> component tree will contain no
   --  nodes.
   --  If the <b>Root</b> pointer is not null, first deletes recursively
   --  the component tree.
   procedure Steal_Root_Component (UI   : in out UIComponent'Class;
                                   Root : in out UIComponent_Access) is
   begin
      if Root /= null then
         Delete (Root);
      end if;
      if UI.First_Child = null then
         Root := null;
      elsif UI.First_Child.Next = null then
         Root := UI.First_Child;
         UI.First_Child := null;
         UI.Last_Child  := null;
      else
         Root := new UIComponent;
         Root.First_Child := UI.First_Child;
         Root.Last_Child  := UI.Last_Child;
         UI.First_Child := null;
         UI.Last_Child  := null;
      end if;
   end Steal_Root_Component;

   procedure Free_Component is
     new Ada.Unchecked_Deallocation (Object => UIComponent'Class,
                                     Name   => UIComponent_Access);

   procedure Free_Attribute is
     new Ada.Unchecked_Deallocation (Object => UIAttribute,
                                     Name   => UIAttribute_Access);

   --  ------------------------------
   --  Delete the component tree recursively.
   --  ------------------------------
   procedure Delete (UI : in out UIComponent_Access) is
   begin
      if UI /= null then
         declare
            C : UIComponent_Access := UI.First_Child;
         begin
            while C /= null loop
               UI.First_Child := C.Next;
               Delete (C);
               C := UI.First_Child;
            end loop;
         end;
         declare
            A : UIAttribute_Access := UI.Attributes;
         begin
            while A /= null loop
               UI.Attributes := A.Next_Attr;
               Free_Attribute (A);
               A := UI.Attributes;
            end loop;
         end;
         Free_Component (UI);
      end if;
   end Delete;

end ASF.Components.Base;
