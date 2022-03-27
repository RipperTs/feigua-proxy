const axios = require('axios');
const redis = require('redis');
var mysql = require('mysql');

const isMaster = true;
const ip = '121.36.110.45';
const client = redis.createClient();
const pool = mysql.createPool({
    host: '121.36.110.45',
    user: 'ineundo_axa2_com',
    password: '5RFk8FM5yYxT4tzy',
    database: 'ineundo_axa2_com',
});

const urls = {
    'feigua.douyin': 'https://dy.feigua.cn/User',
    'feigua.kuaishou': 'https://ks.feigua.cn/User',
};
const names = {
    'feigua.douyin': 'FEIGUA',
    'feigua.kuaishou': 'KUAISHOU',
};

async function checkStatus(accounts) {
    await Promise.all(
        accounts.map(
            (account) =>
                new Promise((resolve) => {
                    (async () => {
                        const platform = [account.platform, account.subplatform].join('.');
                        const url = urls[platform];
                        const name = names[platform];

                        const res = await axios.get(url, {
                            headers: {
                                'User-Agent':
                                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.131 Safari/537.36',
                                Cookie: `${name}=${account.cookie}`,
                            },
                        });

                        if (!~res.data.search(account.accountId)) {
                            console.log(
                                `${new Date().toISOString().slice(0, 19)} ${account.id} ${account.username} ${
                                    account.accountId
                                } offline`
                            );

                            // update mysql status
                            pool.query(`UPDATE ui_account SET status = 0 WHERE account_id = '${account.id}'`);

                            // remove redis user bind cookie cache
                            /*
                            if (isMaster) {
                                client.del(`ineundo:account.id:${account.id}:cookie`);
                                client.lrem(
                                    `ineundo:ip:${account.ip}:platform:${platform}.${account.version}:account.ids`,
                                    0,
                                    account.id
                                );
                            }
                            */
                        } else {
                            console.log(
                                `${new Date().toISOString().slice(0, 19)} ${account.id} ${account.username} ${
                                    account.accountId
                                } online`
                            );

                            // update mysql status
                            if (account.status === 0) {
                                pool.query(`UPDATE ui_account SET status = 1 WHERE account_id = ${account.id}`);
                            }
                        }
                        resolve();
                    })();
                })
        )
    );
}

function getAccounts() {
    return new Promise((resolve, reject) => {
        pool.query(
            `SELECT * FROM ui_account a JOIN ui_server s ON s.server_id = a.server_id JOIN ui_platform p ON p.plantform_id = a.plant_id WHERE ip = '${ip}'`,
            (err, rows) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(
                        rows.map((row) => ({
                            id: row.account_id,
                            ip: row.ip,
                            username: row.account_username,
                            accountId: row.accountID,
                            cookie: row.account_cookie,
                            platform: row.plantformpin,
                            subplatform: row.subplantformpin,
                            version: row.versionpin,
                            status: row.status,
                        }))
                    );
                }
            }
        );
    });
}

(async () => {
    for (;;) {
        try {
            const accounts = await getAccounts();
            await checkStatus(accounts);
        } catch (e) {
            console.log(`Error: ${e}`);
        }
        await new Promise((resolve) => setTimeout(resolve, Math.floor(Math.random() * (30 - 10) + 10) * 1000));
    }
})();
