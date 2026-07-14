// document.addEventListener('DOMContentLoaded', () => {
//   changeOffset()
// })

// window.addEventListener('resize', () => {
//   changeOffset()
// })


// function changeOffset() {
//   const blackListedCards = ['x-large', '2x-small']
//   const cardCollections = document.querySelectorAll('.card-collection')
//   cardCollections.forEach((collection) => {
//     cards = collection.querySelectorAll('.playing-card')
//     let cardType = cards[0]
//     if (cardType) {
//       cardType = cardType.className.split('--')
//       if (blackListedCards.includes(cardType[cardType.length - 1])) return
//     }
//     if (cards.length == 0) return

//     let minOffset = 15 // desktop min offset
//     if (window.innerWidth < 800) minOffset = 3 // mobile min offset

//     const cardWidth = cards[0].width
//     const cardsLength = cards.length
//     let containerWidth = collection.offsetWidth

//     let offset = 0
//     while ((cardsLength * cardWidth) - (offset * cardsLength) > containerWidth - cardWidth) {
//       offset += 1
//     }

//     if (offset < minOffset) offset = minOffset

//     collection.style.marginLeft = `${offset}px`
//     cards.forEach((card) => {
//       card.style.marginLeft = `${offset * -1}px`
//     })
//   })
// }
