{
Copyright (C) 2006-2015 Matteo Salvi

Website: http://www.salvadorsoftware.com/

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
}

unit Forms.Dialog.BaseEntity;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.ComCtrls,
  Vcl.StdCtrls, Frame.BaseEntity, VirtualTrees;

type
  TfrmDialogBase = class(TForm)
    btnOk: TButton;
    btnCancel: TButton;
    pnlDialogPage: TPanel;
    vstCategory: TVirtualStringTree;
    btnApply: TButton;
    procedure btnOkClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure btnApplyClick(Sender: TObject);
  private
    { Private declarations }
    procedure SaveNodeData(Sender: TBaseVirtualTree; Node: PVirtualNode;
                           Data: Pointer; var Abort: Boolean);
    function GetNodeByFrameClass(Tree: TBaseVirtualTree; AFramePage: TPageFrameClass;
                                 Node: PVirtualNode = nil): PVirtualNode;
  strict protected
    FCurrentPage: TfrmBaseEntityPage;
    FDefaultPage: TPageFrameClass;
    FFrameGeneral: PVirtualNode;
    function InternalLoadData: Boolean; virtual;
    function InternalSaveData: Boolean; virtual;
    function AddFrameNode(Tree: TBaseVirtualTree; Parent: PVirtualNode;
                          FramePage: TPageFrameClass): PVirtualNode;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;

    property CurrentPage: TfrmBaseEntityPage read FCurrentPage write FCurrentPage;

    procedure ChangePage(NewPage: TPageFrameClass);
  end;

var
  frmDialogBase: TfrmDialogBase;

implementation

uses
  VirtualTree.Events, Kernel.Types, Kernel.Logger;

{$R *.dfm}

{ TfrmDialogBase }

function TfrmDialogBase.AddFrameNode(Tree: TBaseVirtualTree;
  Parent: PVirtualNode; FramePage: TPageFrameClass): PVirtualNode;
var
  NodeData: PFramesNodeData;
begin
  Result   := Tree.AddChild(Parent);
  NodeData := Tree.GetNodeData(Result);
  if Assigned(NodeData) then
  begin
    NodeData.Frame := FramePage;
    NodeData.Title := TfrmBaseEntityPage(FramePage).Title;
    NodeData.ImageIndex := TfrmBaseEntityPage(FramePage).ImageIndex;
  end;
end;

procedure TfrmDialogBase.btnApplyClick(Sender: TObject);
begin
  //If IterateSubtree returns a value, something is wrong
  if Not Assigned(vstCategory.IterateSubtree(nil, SaveNodeData, nil)) then
    InternalSaveData;
end;

procedure TfrmDialogBase.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmDialogBase.btnOkClick(Sender: TObject);
var
  ResultNode: PVirtualNode;
begin
  //If IterateSubtree returns a value, something is wrong
  ResultNode := vstCategory.IterateSubtree(nil, SaveNodeData, nil);
  if Not Assigned(ResultNode) then
  begin
    if InternalSaveData then
      ModalResult := mrOk;
  end
  else
    ModalResult := mrNone;
end;

procedure TfrmDialogBase.ChangePage(NewPage: TPageFrameClass);
begin
  if Assigned(FCurrentPage) then
  begin
    if FCurrentPage.ClassType = NewPage then
      Exit
    else
     FCurrentPage.Visible := False;
  end;
  FCurrentPage := TfrmBaseEntityPage(NewPage);
  FCurrentPage.Parent  := pnlDialogPage;
  FCurrentPage.Align   := alClient;
  FCurrentPage.Visible := True;
end;

constructor TfrmDialogBase.Create(AOwner: TComponent);
var
  selNode: PVirtualNode;
begin
  inherited;
  TVirtualTreeEvents.Create.SetupVSTDialogFrame(vstCategory);
  //Load frames
  Self.InternalLoadData;
  //Set default page
  if not Assigned(FDefaultPage) then
    selNode := FFrameGeneral
  else
    selNode := GetNodeByFrameClass(Self.vstCategory, FDefaultPage);
  //Select node (automatically open frame using vst's AddToSelection event)
  Self.vstCategory.FocusedNode := selNode;
  Self.vstCategory.Selected[selNode] := True;
  Self.vstCategory.FullExpand;

  Self.pnlDialogPage.TabOrder := 0;
end;

procedure TfrmDialogBase.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Ord(Key) = VK_RETURN then
    btnOkClick(Sender)
  else
    if Ord(Key) = VK_ESCAPE then
      btnCancelClick(Sender);
end;

function TfrmDialogBase.GetNodeByFrameClass(Tree: TBaseVirtualTree;
  AFramePage: TPageFrameClass; Node: PVirtualNode): PVirtualNode;
var
  NodeData: PFramesNodeData;
begin
  Result := nil;

  if Node = nil then
    Node := Tree.GetFirst;

  while Assigned(Node) do
  begin
    NodeData := Tree.GetNodeData(Node);

    if TfrmBaseEntityPage(NodeData.Frame).ClassName = AFramePage.ClassName then
      Exit(Node);

    if Node.ChildCount > 0 then
      Result := GetNodeByFrameClass(Tree, AFramePage, Node.FirstChild);

    Node := Tree.GetNextSibling(Node);
  end;
end;

function TfrmDialogBase.InternalLoadData: Boolean;
begin
  TASuiteLogger.Enter('InternalLoadData', Self);
  Result := True;
end;

function TfrmDialogBase.InternalSaveData: Boolean;
begin
  TASuiteLogger.Enter('InternalSaveData', Self);
  Result := True;
end;

procedure TfrmDialogBase.SaveNodeData(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Data: Pointer; var Abort: Boolean);
var
  NodeData: PFramesNodeData;
begin
  //Call Frame's function SaveData
  NodeData := vstCategory.GetNodeData(Node);
  if Assigned(NodeData) then
    Abort := Not(TfrmBaseEntityPage(NodeData.Frame).SaveData);
end;

end.
