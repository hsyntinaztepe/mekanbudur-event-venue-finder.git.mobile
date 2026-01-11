using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MekanBudur.Api.Models
{
    public class SavedListing
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        public Guid UserId { get; set; }
        [ForeignKey("UserId")]
        public User? User { get; set; }

        public Guid ListingId { get; set; }
        [ForeignKey("ListingId")]
        public EventListing? Listing { get; set; }

        public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    }
}
