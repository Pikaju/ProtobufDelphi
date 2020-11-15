/// <summary>
/// Support code for handling of varint type values in <see cref="N:Com.GitHub.Pikaju.Protobuf.Delphi.uProtobufRepeatedFieldValues"/>.
/// </summary>
unit Com.GitHub.Pikaju.Protobuf.Delphi.uProtobufRepeatedVarintFieldValues;

{$INCLUDE Work.Connor.Delphi.CompilerFeatures.inc}

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  // To extend TProtobufRepeatedPrimitiveFieldValues<T>
  Com.GitHub.Pikaju.Protobuf.Delphi.uProtobufRepeatedPrimitiveFieldValues,
  // TProtobufVarintWireCodec<T> for encoding and decoding of field values
  Com.GitHub.Pikaju.Protobuf.Delphi.uProtobufVarintWireCodec,
  // IProtobufMessageInternal for IProtobufRepeatedFieldValuesInternal<T> implementation
  Work.Connor.Protobuf.Delphi.ProtocGenDelphi.Runtime.Internal.uIProtobufMessageInternal,
  // TProtobufFieldNumber for IProtobufRepeatedFieldValuesInternal<T> implementation
  Work.Connor.Protobuf.Delphi.ProtocGenDelphi.uProtobuf,
  // TStream for IProtobufRepeatedFieldValuesInternal<T> implementation
{$IFDEF WORK_CONNOR_DELPHI_COMPILER_UNIT_SCOPE_NAMES}
  System.Classes;
{$ELSE}
  Classes;
{$ENDIF}

type
  /// <summary>
  /// Helper subclass of <see cref="T:TProtobufRepeatedPrimitiveFieldValues"/> for values of a specific varint type.
  /// </summary>
  /// <typeparam name="T">Delphi type of the field values</typeparam>
  TProtobufRepeatedVarintFieldValues<T> = class abstract(TProtobufRepeatedPrimitiveFieldValues<T>)
    // Abstract members

    protected
      /// <summary>
      /// Getter for <see cref="WireCodec"/>.
      /// </summary>
      /// <returns>Field codec for the varint type</returns>
      function GetWireCodec: TProtobufVarintWireCodec<T>; virtual; abstract;

      /// <summary>
      /// Field codec for the varint type.
      /// </summary>
      property WireCodec: TProtobufVarintWireCodec<T> read GetWireCodec;

    // TProtobufRepeatedFieldValues<T> implementation

    protected
      function ConstructElement: T; override;

    // IProtobufRepeatedFieldValuesInternal<T> implementation

    public
      procedure EncodeAsRepeatedField(aContainer: IProtobufMessageInternal; aField: TProtobufFieldNumber; aDest: TStream); override;
      procedure DecodeAsUnknownRepeatedField(aContainer: IProtobufMessageInternal; aField: TProtobufFieldNumber); override;
  end;

implementation

uses
  // For handling protobuf encoded fields
  Com.GitHub.Pikaju.Protobuf.Delphi.uProtobufEncodedField,
  // TProtobufMessage for message field encoding and decoding
  Com.GitHub.Pikaju.Protobuf.Delphi.uProtobufMessage,
  // For encoding and decoding of protobuf tags
  Com.GitHub.Pikaju.Protobuf.Delphi.uProtobufTag,
  // For encoding and decoding of varint type values
  Com.GitHub.Pikaju.Protobuf.Delphi.uProtobufVarint,
  // TObjectList for handling unparsed fields
{$IFDEF WORK_CONNOR_DELPHI_COMPILER_UNIT_SCOPE_NAMES}
  System.Generics.Collections;
{$ELSE}
  Generics.Collections;
{$ENDIF}

// TProtobufRepeatedFieldValues<T> implementation

function TProtobufRepeatedVarintFieldValues<T>.ConstructElement: T;
begin
  result := WireCodec.GetDefault;
end;

// IProtobufRepeatedFieldValuesInternal<T> implementation

procedure TProtobufRepeatedVarintFieldValues<T>.EncodeAsRepeatedField(aContainer: IProtobufMessageInternal; aField: TProtobufFieldNumber; aDest: TStream);
var
  lValue: T;
begin
  TProtobufTag.WithData(aField, wtLengthDelimited).Encode(aDest);
  for lValue in self do EncodeVarint(WireCodec.ToUInt64(lValue), aDest);
end;

procedure TProtobufRepeatedVarintFieldValues<T>.DecodeAsUnknownRepeatedField(aContainer: IProtobufMessageInternal; aField: TProtobufFieldNumber);
var
  lContainer: TProtobufMessage;
  lFields: TObjectList<TProtobufEncodedField>;
  lField: TProtobufEncodedField;
  lStream: TMemoryStream;
begin
  lContainer := aContainer as TProtobufMessage;

  // Default value for repeated fields is empty.
  Clear;

  lFields := nil;
  lContainer.UnparsedFields.TryGetValue(aField, lFields);
  if (Assigned(lFields)) then
  begin
    // For each field, we will decide wether to decode a packed or non-packed repeated varint.
    for lField in lFields do
    begin
      // Convert field to a stream for simpler processing.
      lStream := TMemoryStream.Create;
      try
        lStream.WriteBuffer(lField.Data[0], Length(lField.Data));
        lStream.Seek(0, soBeginning);

        if (lField.Tag.WireType = wtVarint) then Add(WireCodec.FromUInt64(DecodeVarint(lStream)))
        else if (lField.Tag.WireType = wtLengthDelimited) then
        begin
          // Ignore the size of the field, as the stream already has the correct length.
          DecodeVarint(lStream);
          while (lStream.Position < lStream.Size) do
            Add(WireCodec.FromUInt64(DecodeVarint(lStream)));
        end; // TODO: Catch invalid wire type.
      finally
        lStream.Free;
      end;
    end;
    lContainer.UnparsedFields.Remove(aField);
  end;
end;

end.

