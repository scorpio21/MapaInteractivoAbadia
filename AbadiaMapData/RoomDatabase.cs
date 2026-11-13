using System.Text.Json;
using System.Text.Json.Serialization;

namespace AbadiaMapData;

public sealed class RoomDatabase
{
    private readonly Dictionary<(int Floor, int Number), RoomInfo> _rooms;

    private RoomDatabase(IEnumerable<RoomInfo> rooms)
    {
        _rooms = rooms.ToDictionary(r => (r.Floor, r.Number));
    }

    public static RoomDatabase FromJson(string json)
    {
        var data = JsonSerializer.Deserialize<RoomDataFile>(json,
            new JsonSerializerOptions { PropertyNameCaseInsensitive = true })
            ?? throw new InvalidDataException("JSON de habitaciones vacío.");
        if (data.Rooms is null)
            throw new InvalidDataException("No existe el campo rooms.");
        return new RoomDatabase(data.Rooms);
    }

    public RoomInfo? GetRoomPosition(int floor, int number) =>
        _rooms.GetValueOrDefault((floor, number));

    public RoomInfo? GetRoomAtPosition(int floor, double x, double y)
    {
        // Solo devuelve habitaciones conocidas y evita elegir una vecina
        // si el punto está fuera de su celda. Los centros de las plantas
        // superiores siguen pendientes de validación visual.
        return _rooms.Values.FirstOrDefault(r =>
            r.Floor == floor && GridCalculator.Contains(r, x, y));
    }

    public int GetGridSize(int floor) => GridCalculator.GetGridSize(floor);
    public int Count => _rooms.Count;

    private sealed class RoomDataFile
    {
        [JsonPropertyName("rooms")]
        public List<RoomInfo>? Rooms { get; set; }
    }
}
