'reach 0.1';

const commonInteract = {
  reportCancellation: Fun([], Null),
  reportPayment: Fun([UInt], Null),
};
const oracleInteract = {
  ...commonInteract,
  price: UInt,
  wisdom: Bytes(128),
  reportReady: Fun([UInt], Null),
};
const seekerInteract = {
  ...commonInteract,
  confirmPurchase: Fun([UInt], Bool),
  reportWisdom: Fun([Bytes(128)], Null)
};

export const main = Reach.App(() => {
    const O = Participant('Oracle', oracleInteract);
    const S = Participant('Seeker', seekerInteract);
    const V = View('Main', { price: UInt });
    init();

    O.only(() => { const price = declassify(interact.price); });
    O.publish(price);
    O.interact.reportReady(price);
    V.price.set(price);
    commit();
  
    S.only(() => { const willBuy = declassify(interact.confirmPurchase(price)); });
    S.publish(willBuy);
    if (!willBuy) {
      commit();
      each([O, S], () => interact.reportCancellation());
      exit();
    } else {
      commit();
    }
    S.pay(price);
    each([O, S], () => interact.reportPayment(price));
    commit();
    O.only(() => { const wisdom = declassify(interact.wisdom); });
    O.publish(wisdom);
    transfer(price).to(O);
    commit();
    S.interact.reportWisdom(wisdom);
    exit();
})