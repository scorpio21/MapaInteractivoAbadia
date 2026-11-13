using Godot;
using AbadiaMapData;
using System;

public partial class RoomDataBridge : Node
{
    private RoomDatabase? _database;

    public override void _Ready()
    {
        const string path = "res://data/habitaciones.json";
        if (!FileAccess.FileExists(path))
        {
            GD.PushError($"No se encuentra {path}");
            return;
        }
        try
        {
            _database = RoomDatabase.FromJson(FileAccess.GetFileAsString(path));
        }
        catch (Exception ex)
        {
            GD.PushError($"Error al leer habitaciones: {ex.Message}");
        }
    }

    public bool IsReady() => _database is not null;
    public int GetGridSize(int floor) => _database?.GetGridSize(floor) ?? -1;

    // Godot expone tipos Variant compatibles: Vector2 y enteros.
    // Vector2(-1,-1) indica habitación inexistente.
    public Vector2 GetRoomPosition(int floor, int number)
    {
        var room = _database?.GetRoomPosition(floor, number);
        return room is null ? new Vector2(-1, -1) : new Vector2(room.X, room.Y);
    }

    // Devuelve -1 si no hay habitación conocida bajo el punto.
    public int GetRoomAtPosition(int floor, float x, float y) =>
        _database?.GetRoomAtPosition(floor, x, y)?.Number ?? -1;
}
