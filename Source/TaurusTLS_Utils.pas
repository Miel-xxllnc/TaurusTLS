unit TaurusTLS_Utils;

{$I TaurusTLSCompilerDefines.inc}

interface

{ ****************************************************************************** }
{ *  TaurusTLS                                                                 * }
{ *           https://github.com/JPeterMugaas/TaurusTLS                        * }
{ *                                                                            * }
{ *  Copyright (c) 2024 TaurusTLS Developers, All Rights Reserved              * }
{ *                                                                            * }
{ * Portions of this software are Copyright (c) 1993 � 2018,                   * }
{ * Chad Z. Hower (Kudzu) and the Indy Pit Crew � http://www.IndyProject.org/  * }
{ ****************************************************************************** }
{$I TaurusTLSLinkDefines.inc}

uses
  IdCTypes,
  IdGlobal,
  IdGlobalProtocols,
  TaurusTLSHeaders_asn1,
  TaurusTLSHeaders_evp,
  TaurusTLSHeaders_ossl_typ,
  TaurusTLSHeaders_x509v3,
  Classes;

{$I TaurusTLSIndyVers.inc}

type
  /// <summary>
  /// Message Digest.
  /// </summary>
  TTaurusTLSLEVP_MD = record
    _Length: TIdC_UINT;
    MD: Array [0 .. EVP_MAX_MD_SIZE - 1] of TIdAnsiChar;
  end;

  /// <summary>
  /// Converts an OpenSSL ASN1 String to a hexidecimal representation.
  /// </summary>
  /// <param name="a">
  /// Pointer to the OpenSSL ASN1_STRING to convert.
  /// </param>
  /// <returns>
  /// Hexidecimal representation of the value of the string.
  /// </returns>
  /// <remarks>
  /// The function returns an empty string if the A parameter is nil.
  /// </remarks>
function ASN1_STRING_ToHexStr(a: PASN1_STRING): String;
/// <summary>
/// Converts an OpenSSL ASN1_OBJECT value to a string.
/// </summary>
/// <param name="a">
/// Pointer to the ASN1_OBJECT.
/// </param>
/// <returns>
/// The textual representation of the ASN1_OBJECT's value.
/// </returns>
/// <remarks>
/// May return an empty string if the a parameter is nil.
/// </remarks>
function ASN1_OBJECT_ToStr(a: PASN1_OBJECT): String;
/// <summary>
/// Converts a series of bytes to their hexidecimal representation.
/// </summary>
/// <param name="APtr">
/// Pointer to the bytes to convert.
/// </param>
/// <param name="ALen">
/// number of bytes to convert.
/// </param>
/// <returns>
/// Hexidecimal representation of the bytes.
/// </returns>
/// <remarks>
/// An empty string may be returned if APtr is nil or the ALen parameter is 0.
/// </remarks>
function BytesToHexString(APtr: Pointer; ALen: TIdC_SIZET): String;
/// <summary>
/// Converts a TTaurusTLSLEVP_MD record to a hexidecimal representation.
/// </summary>
/// <param name="AMD">
/// The TTaurusTLSLEVP_MD to convert.
/// </param>
/// <returns>
/// The hexidecimal representation.
/// </returns>
function MDAsString(const AMD: TTaurusTLSLEVP_MD): String;
/// <summary>
/// Parses an ASN1_TIME into a time stamp.
/// </summary>
/// <param name="a">
/// Pointer to the OpenSSL ASN1_TIME object to parse.
/// </param>
/// <param name="year">
/// Returns the year
/// </param>
/// <param name="month">
/// Returns the month
/// </param>
/// <param name="day">
/// Returns the day of the month.
/// </param>
/// <param name="hour">
/// Returns the Hour of the day.
/// </param>
/// <param name="min">
/// Returns the minute of the hour.
/// </param>
/// <param name="sec">
/// Returns the second of the minute.
/// </param>
/// <param name="tz_hour">
/// Returns the Time Zone offset hour
/// </param>
/// <param name="tz_min">
/// Returns the Time Zone offset minute.
/// </param>
/// <returns>
/// True if parsing was successful or False if failed.
/// </returns>
function ASN1_Time_Decode(const a: PASN1_TIME; out year, month, day, hour, min,
  sec: Word; out tz_hour, tz_min: Integer): Boolean;

/// <summary>
/// Converts a ASN1_TIME to a TDateTime time stamp.
/// </summary>
/// <param name="a">
/// The Pointer to the OpenSSL ASN1_TIME to convert.
/// </param>
/// <returns>
/// The value as a TDateTime.
/// </returns>
/// <remarks>
/// The return value may be 0 if the conversion failed.
/// </remarks>
function ASN1TimeToDateTime(a: PASN1_TIME): TDateTime;

/// <summary>
///   Convert an OpenSSL ASN1_OCTET_STRING to an IP address.
/// </summary>
/// <param name="a">
///   Pointer to the ASN1_OCTET_STRING to convert.
/// </param>
/// <returns>
///   The IP address or an empty string if the a parameter is nil or the value
///   is not a valid IP address.
/// </returns>
function ASN1_ToIPAddress(const a: PASN1_OCTET_STRING): String;
/// <summary>
///   Converts an OpenSSL X509_NAME object to a string representation.
/// </summary>
/// <param name="ADirName">
///   Pointer to an OpenSSL X509_NAME object.
/// </param>
/// <returns>
///   The value as a textual representation or an empty string if the ADirName parameter is nil.
/// </returns>
function DirName(const ADirName: PX509_NAME): String;
/// <summary>
///   Converts an OpenSSL GENERAL_NAME object to a string representation.
/// </summary>
/// <param name="AGN">
///   Pointer to an OpenSSL GENERAL_NAME object.
/// </param>
/// <returns>
///   The value as a textual representation or an empty string if the AGN
///   parameter is nil.
/// </returns>
function GeneralNameToStr(const AGN: PGENERAL_NAME): String;

{$IFNDEF HAS_RAW_TO_BYTES_64_BIT}
/// <summary>
/// Converts to series ot bytes to a TIdBytes.
/// </summary>
/// <param name="AValue">
/// Pointer to the bytes to convert.
/// </param>
/// <param name="ASize">
/// The number of bytes to convert.
/// </param>
/// <returns>
/// The TIdBytes.
/// </returns>
/// <remarks>
/// The function may not be present if the Indy version is greater than 10.6.
/// </remarks>
function TaurusTLSRawToBytes(const AValue; const ASize: TIdC_SIZET): TIdBytes;
{$ENDIF}

implementation

uses TaurusTLSHeaders_bio, TaurusTLSHeaders_objects, TaurusTLSHeaders_x509,
  SysUtils;

{$IFNDEF HAS_RAW_TO_BYTES_64_BIT}

function TaurusTLSRawToBytes(const AValue; const ASize: TIdC_SIZET): TIdBytes;
{$IFDEF USE_INLINE}inline; {$ENDIF}
begin
  SetLength(Result, ASize);
  if ASize > 0 then
  begin
    Move(AValue, Result[0], ASize);
  end;
end;
{$ENDIF}

function ASN1_STRING_ToHexStr(a: PASN1_STRING): String;
{$IFDEF USE_INLINE} inline; {$ENDIF}
var
  LPtr: PAnsiChar;
  LLen: TIdC_INT;
begin
  Result := '';
  if Assigned(a) then
  begin
    LPtr := PAnsiChar(ASN1_STRING_get0_data(a));
    LLen := ASN1_STRING_length(a);
    Result := BytesToHexString(LPtr, LLen);
  end;
end;

function BytesToHexString(APtr: Pointer; ALen: TIdC_SIZET): String;
{$IFDEF USE_INLINE} inline; {$ENDIF}
var
  i: TIdC_SIZET;
  LPtr: PByte;
begin
  Result := '';
  if Assigned(APtr) then
  begin
    LPtr := PByte(APtr);
    for i := 0 to ALen - 1 do
    begin
      if i <> 0 then
      begin
        Result := Result + ':'; { Do not Localize }
      end;
      Result := Result + IndyFormat('%.2x', [LPtr^]);
      Inc(LPtr);
    end;
  end;
end;

function MDAsString(const AMD: TTaurusTLSLEVP_MD): String;
{$IFDEF USE_INLINE} inline; {$ENDIF}
var
  i: TIdC_UINT;
begin
  Result := '';
  for i := 0 to AMD._Length - 1 do
  begin
    if i <> 0 then
    begin
      Result := Result + ':'; { Do not Localize }
    end;
    Result := Result + IndyFormat('%.2x', [Byte(AMD.MD[i])]);
    { do not localize }
  end;
end;

function ASN1_OBJECT_ToStr(a: PASN1_OBJECT): String;
{$IFNDEF USE_INLINE_VAR}
var
  LBuf: array [0 .. 1024] of TIdAnsiChar;
{$ENDIF}
begin
  if Assigned(a) then
  begin
{$IFDEF USE_INLINE_VAR}
    var
      LBuf: array [0 .. 1024] of TIdAnsiChar;
{$ENDIF}
    OBJ_obj2txt(@LBuf[0], 1024, a, 0);
    Result := String(LBuf);
  end
  else
  begin
    Result := '';
  end;
end;

function ASN1_Time_Decode(const a: PASN1_TIME; out year, month, day, hour, min,
  sec: Word; out tz_hour, tz_min: Integer): Boolean;
var
  i, tz_dir: Integer;
  time_str: string;
{$IFNDEF USE_MARSHALLED_PTRS}
{$IFNDEF STRING_IS_ANSI}
  LTemp: AnsiString;
{$ENDIF}
{$ENDIF}
begin
  year := 0;
  month := 1;
  day := 1;
  hour := 0;
  min := 0;
  sec := 0;
  tz_hour := 0;
  tz_min := 0;
  Result := False; { default is to return with an error indication }
  if a^._Length < 12 then
  begin
    Exit;
  end;
{$IFDEF USE_MARSHALLED_PTRS}
  time_str := TMarshal.ReadStringAsAnsi(TPtrWrapper.Create(UTCtime^.data),
    UTCtime^._Length);
{$ELSE}
{$IFDEF STRING_IS_ANSI}
  SetString(time_str, PAnsiChar(a^.data), a^._Length);
{$ELSE}
  SetString(LTemp, PAnsiChar(a^.data), a^._Length);
  { Note: UTCtime is a type defined by OpenSSL and hence is ansistring and not UCS-2 }
  // TODO: do we need to use SetCodePage() here?
  time_str := String(LTemp); // explicit convert to Unicode
{$ENDIF}
{$ENDIF}
  // Check if first 12 chars are numbers
  if not IsNumeric(time_str, 12) then
  begin
    Exit;
  end;
  // Convert time from string to number
  year := IndyStrToInt(Copy(time_str, 1, 2)) + 1900;
  month := IndyStrToInt(Copy(time_str, 3, 2));
  day := IndyStrToInt(Copy(time_str, 5, 2));
  hour := IndyStrToInt(Copy(time_str, 7, 2));
  min := IndyStrToInt(Copy(time_str, 9, 2));
  sec := IndyStrToInt(Copy(time_str, 11, 2));
  // Fix year. This function is Y2k but isn't compatible with Y2k5 :-(    {Do not Localize}
  if year < 1950 then
  begin
    Inc(year, 100);
  end;
  // Check TZ
  tz_hour := 0;
  tz_min := 0;
  if CharIsInSet(time_str, 13, '-+') then
  begin { Do not Localize }
    tz_dir := iif(CharEquals(time_str, 13, '-'), -1, 1); { Do not Localize }
    for i := 14 to 18 do
    begin // Check if numbers are numbers
      if i = 16 then
      begin
        Continue;
      end;
      if not IsNumeric(time_str[i]) then
      begin
        Exit;
      end;
    end;
    tz_hour := IndyStrToInt(Copy(time_str, 14, 15)) * tz_dir;
    tz_min := IndyStrToInt(Copy(time_str, 17, 18)) * tz_dir;
  end;
  Result := True; { everthing OK }
end;

function ASN1TimeToDateTime(a: PASN1_TIME): TDateTime;
var
  year: Word;
  month: Word;
  day: Word;
  hour: Word;
  min: Word;
  sec: Word;
  tz_h: Integer;
  tz_m: Integer;
begin
  Result := 0;
  if ASN1_Time_Decode(a, year, month, day, hour, min, sec, tz_h, tz_m) then
  begin
    Result := EncodeDate(year, month, day) + EncodeTime(hour, min, sec, 0);
    Result := Result + (tz_m / (60 * 24));
    Result := Result + (tz_h / 24.0);
    Result := UTCTimeToLocalTime(Result);
  end;
end;

function DirName(const ADirName: PX509_NAME): String;
var
  i, Le_count: TIdC_INT;
  LE: PX509_NAME_ENTRY;
  LASN1: PASN1_STRING;
  LOBJ: PASN1_OBJECT;
  LPtr: PAnsiChar;
begin
  Result := '';
  Le_count := X509_NAME_entry_count(ADirName);

  for i := 0 to Le_count - 1 do
  begin
    LE := X509_NAME_get_entry(ADirName, i);
    LOBJ := X509_NAME_ENTRY_get_object(LE);
    LASN1 := X509_NAME_ENTRY_get_data(LE);
    LPtr := PAnsiChar(ASN1_STRING_get0_data(LASN1));
    Result := Result + ' ' + ASN1_OBJECT_ToStr(LOBJ) + ' = ' +
      String(LPtr) + ';';
  end;
  Result := Trim(Result);
end;

function ASN1_ToIPAddress(const a: PASN1_OCTET_STRING): String;
{$IFDEF USE_INLINE}inline; {$ENDIF}
var
  LIPv6: TIdIPv6Address;
  i: Integer;
begin
  Result := '';
  if Assigned(a) then
  begin
    if a._Length = 4 then
    begin
      Result := IntToStr(a.data[0]) + '.' + IntToStr(a.data[1]) + '.' +
        IntToStr(a.data[2]) + '.' + IntToStr(a.data[3]);
    end
    else
    begin
      if a._Length = 16 then
      begin

        for i := 0 to 7 do
        begin
          LIPv6[i] := (a.data[i * 2] shl 8) + (a.data[(i * 2) + 1]);
        end;
        Result := IdGlobal.IPv6AddressToStr(LIPv6);
      end;
    end;
  end;
end;

function GeneralNameToStr(const AGN: PGENERAL_NAME): String;
begin
  Result := '';
  case AGN.type_ of
    GEN_OTHERNAME:
      Result := 'Other Name';
    GEN_EMAIL:
      begin
        Result := 'E-Mail: ' + String(PAnsiChar(AGN.d.rfc822Name.data));
      end;
    GEN_DNS:
      begin
        Result := 'DNS: ' + String(PAnsiChar(AGN.d.dNSName.data));
      end;
    GEN_X400:
      begin
        Result := 'X400';
      end;
    GEN_DIRNAME:
      begin
        Result := 'Dir Name: ' + DirName(AGN.d.directoryName);
      end;
    GEN_EDIPARTY:
      begin
        Result := 'EDI Party';
      end;
    GEN_URI:
      begin
        Result := 'URI: ' +
          String(PIdAnsiChar(AGN.d.uniformResourceIdentifier.data));
      end;
    GEN_IPADD:
      begin
        Result := 'IP Address: ' + ASN1_ToIPAddress(AGN.d.iPAddress);
      end;
    GEN_RID:
      Result := 'Registered ID: ' + ASN1_OBJECT_ToStr(AGN.d.rid);
  end;
end;

end.
