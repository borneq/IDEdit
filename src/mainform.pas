unit mainform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ActnList,
  ComCtrls, ExtCtrls, ATSynEdit, NicePages, intfs, Messages;

type

  { TForm1 }

  TForm1 = class(TForm)
    actFileNew: TAction;
    actFileOpen: TAction;
    actFileClosePage: TAction;
    actFileSave: TAction;
    actFileSaveAs: TAction;
    actFileSaveAll: TAction;
    actSearchReplace: TAction;
    actSearchFindPrevious: TAction;
    actSearchFindNext: TAction;
    actSearchFind: TAction;
    actlSearch: TActionList;
    actViewWordWrap: TAction;
    actlView: TActionList;
    actRevert: TAction;
    actlFile: TActionList;
    imglFile16: TImageList;
    imglSearch16: TImageList;
    imglTb16: TImageList;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem10: TMenuItem;
    MenuItem11: TMenuItem;
    MenuItem12: TMenuItem;
    MenuItem13: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    MenuItem9: TMenuItem;
    miFileClosePage: TMenuItem;
    miFileOpen: TMenuItem;
    miFileNew: TMenuItem;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    Timer1: TTimer;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    procedure actFileClosePageExecute(Sender: TObject);
    procedure actFileClosePageUpdate(Sender: TObject);
    procedure actFileNewExecute(Sender: TObject);
    procedure actFileOpenExecute(Sender: TObject);
    procedure actFileSaveAsExecute(Sender: TObject);
    procedure actFileSaveExecute(Sender: TObject);
    procedure actFileSaveUpdate(Sender: TObject);
    procedure actRevertExecute(Sender: TObject);
    procedure actRevertUpdate(Sender: TObject);
    procedure actSearchFindExecute(Sender: TObject);
    procedure actSearchFindNextExecute(Sender: TObject);
    procedure actSearchFindNextUpdate(Sender: TObject);
    procedure actSearchFindPreviousExecute(Sender: TObject);
    procedure actSearchFindPreviousUpdate(Sender: TObject);
    procedure actSearchFindUpdate(Sender: TObject);
    procedure actSearchReplaceExecute(Sender: TObject);
    procedure actSearchReplaceUpdate(Sender: TObject);
    procedure actViewWordWrapExecute(Sender: TObject);
    procedure actViewWordWrapUpdate(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Timer1Timer(Sender: TObject);
  private
    fNotebook: TNicePages;
    fDocumentFactory: IDocumentFactory;
    procedure DoOpenFile(AFileName: string);
  protected
    fWasActivated: boolean;
    function CmdLineOpenFiles: boolean;
    procedure AppActivate(Sender: TObject);
    procedure TabBeforeCloseQuery(Control: TNicePages; Index: Integer; var Consider: TConsiderEnum);
    procedure TabCloseQuery(Control: TNicePages; Index: Integer; var CanClose: TCloseEnum);
    procedure TabClose(Control: TNicePages; Index: Integer);
    procedure TabDraw(Control: TNicePages; Index: Integer; IsActive: Boolean; ACanvas: TCanvas; var R: TRect; var DefaultDraw: boolean);
    procedure ActivateSheet(Control: TNicePages; Index: integer);
  public
    procedure UniqInstOtherInstance(Sender: TObject;
      ParamCount: Integer; const Parameters: array of String);
  end;

var
  Form1: TForm1;

implementation
uses
  LCLType, documentfactory, config;

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  fNotebook:=TNicePages.Create(self);
  InsertControl(fNotebook);
  fNotebook.Align:=alClient;
  fNotebook.TabPosition:=tpBottom;
  fNotebook.OnBeforeCloseQuery:=@TabBeforeCloseQuery;
  fNotebook.OnCloseQuery:=@TabCloseQuery;
  fNotebook.OnClose:=@TabClose;
  fNotebook.OnDrawTab:=@TabDraw;
  fNotebook.OnActivateSheet:=@ActivateSheet;
  fDocumentFactory:=TDocumentFactory.Create(fNotebook);
  Application.AddOnActivateHandler(@AppActivate,false);
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  if fDocumentFactory<> nil then
    fDocumentFactory.TryCloseAll;
  {WriteIniSettings;
  NewIniTimeSize;
  EdFolders.Free;}
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  Number: integer;
begin
  if Key in [ord('0')..Ord('9')] then
  begin
    if Shift<>[ssAlt] then exit;
    if Key>ord('0') then Number := Key-ord('1')
    else Number := 9;
    if Number<fNotebook.PageCount then
      fNotebook.PageIndex:=Number;
    Key:=0;//to avoid beep
  end else if (Key=VK_TAB) and (ssCtrl in Shift) then
  begin
    if ssShift in Shift then
      fNotebook.ActivePrev()
    else
      fNotebook.ActiveNext();
  end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  AppActivate(Sender);
end;

procedure TForm1.DoOpenFile(AFileName: string);
var
  i: integer;
  LDocument: IDocument;
begin
  if AFileName <> '' then
  begin
    // activate the editor if already open
    for i := fDocumentFactory.GetDocumentCount-1 downto 0 do
    begin
      LDocument := fDocumentFactory.GetDocument(i);
      if LDocument.ComparePathWith(AFileName) = 0 then
      begin
        LDocument.Activate;
        exit;
      end;
    end;
  end;
  LDocument := fDocumentFactory.CreateNew(AFileName);
  LDocument.OpenFile(AFileName);
  LDocument.Activate;
end;

function TForm1.CmdLineOpenFiles: boolean;
var
  i: integer;
begin
  for i:=1 to ParamCount do
    DoOpenFile(ParamStr(i));
  result:=ParamCount>1;
end;

procedure TForm1.AppActivate(Sender: TObject);
var
  i: integer;
  LDocument: IDocument;
begin
  for i := 0 to fDocumentFactory.GetDocumentCount-1 do
  begin
    LDocument := fDocumentFactory.GetDocument(i);
    LDocument.CheckWithDisk;
  end;
  for i := 0 to fDocumentFactory.GetDocumentCount-1 do
  begin
    LDocument := fDocumentFactory.GetDocument(i);
    if LDocument.ChangedOutside then
    begin
      LDocument.Activate;
      if MessageDlg('File ' + LDocument.GetPath + ' changed outside. Revert?', mtWarning, [mbYes, mbCancel], 0) = mrYes then
           LDocument.Revert;
    end;
  end;
end;

procedure TForm1.TabBeforeCloseQuery(Control: TNicePages; Index: Integer;
  var Consider: TConsiderEnum);
var
  LDocument: IDocument;
begin
  LDocument := fDocumentFactory.GetDocument(Index);
  Consider := LDocument.Consider();
end;

procedure TForm1.TabCloseQuery(Control: TNicePages; Index: Integer;
  var CanClose: TCloseEnum);
var
  LDocument: IDocument;
begin
  LDocument := fDocumentFactory.GetDocument(Index);
  LDocument.AskSaveChangesBeforeClosing(CanClose);
end;

procedure TForm1.TabClose(Control: TNicePages; Index: Integer);
var
  LDocument: IDocument;
begin
  LDocument := fDocumentFactory.GetDocument(Index);
  LDocument.ActionsBeforeClose();
end;

procedure TForm1.TabDraw(Control: TNicePages; Index: Integer;
  IsActive: Boolean; ACanvas: TCanvas; var R: TRect; var DefaultDraw: boolean);
var
  LDocument: IDocument;
begin
  LDocument := fDocumentFactory.GetDocument(Index);
  if LDocument.GetModified then ACanvas.Font.Color:=clRed
  else ACanvas.Font.Color:=clBlack;
end;

procedure TForm1.ActivateSheet(Control: TNicePages; Index: integer);
var
  LDocument: IDocument;
begin
  LDocument := fDocumentFactory.GetDocument(Index);
  LDocument.AfterActivation;
end;

procedure TForm1.UniqInstOtherInstance(Sender: TObject;
  ParamCount: Integer; const Parameters: array of String);
var
  i: integer;
begin
  Application.Minimize; // this is what really...
  Application.Restore;  // brings a form to top
  Application.BringToFront; // just in case, for orher platforms
  for i:=0 to ParamCount-1 do
    DoOpenFile(Parameters[i]);
end;

procedure TForm1.actFileOpenExecute(Sender: TObject);
begin
  if OpenDialog.Execute then
    DoOpenFile(OpenDialog.FileName);
end;

procedure TForm1.actFileSaveAsExecute(Sender: TObject);
var
  LDocument: IDocument;
begin
  LDocument:=fDocumentFactory.GetActive;
  SaveDialog.FileName:=LDocument.GetPath;
  if SaveDialog.Execute then
    LDocument.SaveAs(SaveDialog.FileName);
end;

procedure TForm1.actFileSaveExecute(Sender: TObject);
var
  LDocument: IDocument;
begin
  LDocument:=fDocumentFactory.GetActive;
  if LDocument.GetPath='' then
  begin
    if SaveDialog.Execute then
      LDocument.SaveAs(SaveDialog.FileName);
  end
  else
  LDocument.Save();
end;

procedure TForm1.actFileSaveUpdate(Sender: TObject);
begin
  actFileSave.Enabled := fDocumentFactory.GetDocumentCount>0;
end;

procedure TForm1.actRevertExecute(Sender: TObject);
begin
  fDocumentFactory.GetActive.Revert;
end;

procedure TForm1.actRevertUpdate(Sender: TObject);
begin
  actRevert.Enabled := (fDocumentFactory.GetDocumentCount>0) and (fDocumentFactory.GetActive.GetPath<>'');
end;

procedure TForm1.actSearchFindExecute(Sender: TObject);
begin
  fDocumentFactory.GetActive.ExecFind;
end;

procedure TForm1.actSearchFindNextExecute(Sender: TObject);
begin
  fDocumentFactory.GetActive.ExecFindNext;
end;

procedure TForm1.actSearchFindUpdate(Sender: TObject);
begin
  actSearchFind.Enabled := fDocumentFactory.GetDocumentCount>0;
end;

procedure TForm1.actSearchReplaceExecute(Sender: TObject);
begin
  fDocumentFactory.GetActive.ExecReplace;
end;

procedure TForm1.actSearchReplaceUpdate(Sender: TObject);
begin
  actSearchReplace.Enabled := fDocumentFactory.GetDocumentCount>0;
end;

procedure TForm1.actSearchFindNextUpdate(Sender: TObject);
begin
  actSearchFindNext.Enabled := fDocumentFactory.GetDocumentCount>0;
end;

procedure TForm1.actSearchFindPreviousExecute(Sender: TObject);
begin
  fDocumentFactory.GetActive.ExecFindPrev;
end;

procedure TForm1.actSearchFindPreviousUpdate(Sender: TObject);
begin
  actSearchFindPRevious.Enabled := fDocumentFactory.GetDocumentCount>0;
end;

procedure TForm1.actViewWordWrapExecute(Sender: TObject);
var
  LDocument: IDocument;
begin
  LDocument:=fDocumentFactory.GetActive;
  actViewWordWrap.Checked:=not actViewWordWrap.Checked;
  LDocument.WordWrap:=actViewWordWrap.Checked;
end;

procedure TForm1.actViewWordWrapUpdate(Sender: TObject);
begin
  actViewWordWrap.Enabled := fDocumentFactory.GetDocumentCount>0;
  actViewWordWrap.Checked:= fDocumentFactory.GetActive.WordWrap;
end;

procedure TForm1.FormActivate(Sender: TObject);
begin
  inherited;
  try
    if not fWasActivated then CmdLineOpenFiles;
  finally
    fWasActivated := true
  end;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  CanClose := fNotebook.TryCloseAll=clClose;
end;

procedure TForm1.actFileNewExecute(Sender: TObject);
begin
  DoOpenFile('');
end;

procedure TForm1.actFileClosePageUpdate(Sender: TObject);
begin
  actFileClosePage.Enabled := fDocumentFactory.GetDocumentCount>0;
end;

procedure TForm1.actFileClosePageExecute(Sender: TObject);
var
  LDocument: IDocument;
begin
  LDocument := fDocumentFactory.GetActive;
  if LDocument<>nil then
    LDocument.TryClose;
end;

end.

