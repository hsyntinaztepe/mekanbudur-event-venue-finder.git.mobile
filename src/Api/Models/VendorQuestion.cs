using System.ComponentModel.DataAnnotations;

namespace MekanBudur.Api.Models
{
    public class VendorQuestion
    {
        public Guid Id { get; set; } = Guid.NewGuid();

        public Guid VendorUserId { get; set; }
        public User VendorUser { get; set; } = default!;

        public Guid MemberUserId { get; set; }
        public User MemberUser { get; set; } = default!;

        [Required, MaxLength(500)]
        public string Question { get; set; } = default!;

        [MaxLength(1000)]
        public string? Answer { get; set; }

        public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
        public DateTime? AnsweredAtUtc { get; set; }
    }
}
