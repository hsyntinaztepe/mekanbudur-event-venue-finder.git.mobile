using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace MekanBudur.Api.Models
{
    public class User
    {
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required, MaxLength(200)]
        public string Email { get; set; } = default!;

        [Required]
        [JsonIgnore]
        public string PasswordHash { get; set; } = default!;

        [MaxLength(120)]
        public string? DisplayName { get; set; }

        public UserRole Role { get; set; } = UserRole.User;

        public VendorProfile? VendorProfile { get; set; }
        public List<EventListing> ListingsCreated { get; set; } = new();
        public List<VendorRating> RatingsGiven { get; set; } = new();
        public List<VendorRating> RatingsReceived { get; set; } = new();
    }
}
