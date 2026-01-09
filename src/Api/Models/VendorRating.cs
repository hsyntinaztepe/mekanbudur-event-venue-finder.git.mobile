using System.ComponentModel.DataAnnotations;

namespace MekanBudur.Api.Models
{
    public class VendorRating
    {
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        public Guid VendorUserId { get; set; }
        public User VendorUser { get; set; } = default!;

        [Required]
        public Guid MemberUserId { get; set; }
        public User MemberUser { get; set; } = default!;

        [Range(1, 5)]
        public int Rating { get; set; }

        [MaxLength(1000)]
        public string? Comment { get; set; }

        public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAtUtc { get; set; }
    }
}
